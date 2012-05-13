op = require './opcodes'
utils = require './utils'

class Scope
  constructor: ->
    @continueSlots = []
    @breakSlots = []

class ScopeChain
  constructor: (@codeObj) -> @_chain = []

  pushScope: -> @_chain.push new Scope
  
  popScope: -> @_chain.pop()

  patchContinue: (label) ->
    throw new Error 'No scope in chain' if @_chain.length < 1
    top = @_chain[@_chain.length - 1]
    top.continueSlots.forEach (slot) =>
      @codeObj._currentCode[slot] = label

  patchBreak: (label) ->
    throw new Error 'No scope in chain' if @_chain.length < 1
    top = @_chain[@_chain.length - 1]
    top.breakSlots.forEach (slot) =>
      @codeObj._currentCode[slot] = label

  addBreakSlot: (slot) ->
    top = @_chain[@_chain.length - 1]
    top.breakSlots.push slot

  addContinueSlot: (slot) ->
    top = @_chain[@_chain.length - 1]
    top.continueSlots.push slot

class LogoFunction
  constructor: (@name, @argc) ->
  invoke: (args) ->
    if args.length isnt @argc
      throw new Error "#{name}() takes exactly #{@argc} arguments (#{argc.length} given)"

class BuiltinFunction extends LogoFunction
  constructor: (name, argc, @func) -> super name, argc
  # It is invoked by VM
  invoke: (args) ->
    super.call this, args
    # We should bind context of @func in advance
    return @func.apply null, args

class UserFunction extends LogoFunction
  constructor: (name, argc) ->
    super name, argc
    @code = []
  # When invoked by VM, it should pass bytecode back to VM.
  # We should also bind 'visitor' in advance.
  invoke: (visitor, args) ->
    super.call this. args
    visitor @code, args

@BuiltinFunction = BuiltinFunction
@UserFunction = UserFunction

# This is the generated code object of our script.
class @CodeObject
  constructor: (consts, globals, funcs, locals) ->
    # TODO builtin functions
    @scopes = new ScopeChain this
    @code = []
    # current generate context is @code
    @_currentCode = @code
    # init names
    @constNames = @_initConsts consts
    @globalNames = @_initGlobalNames globals
    @funcInfos = @_initFuncInfos funcs
    @functions = []
    @localNames = @_initLocalNames locals

  startFuncCode: (funcNum) ->
    func = @funcInfos[funcNum]
    @functions[funcNum] = new UserFunction func.name, func.argc
    @_currentCode = @functions[funcNum].code

  endFuncCode: (funcNum) -> @_currentCode = @code

  addBuiltinFuncs: (builtins) ->
    @functions[i] = builtins[i] for [0...builtins.length]

  # process constant table
  _initConsts: (consts) ->
    _array = []
    consts.forEach (obj, nr) ->
      _array.push [obj, nr]
    _array.sort (x, y) -> x[1] - y[1]
    x[0] for x in _array

  # process global variables
  _initGlobalNames: (globals) ->
    _array = []
    globals.forEach (name, ste) ->
      _array.push [name, ste.number]
    _array.sort (x, y) -> x[1] - y[1]
    x[0] for x in _array

  # process functions
  _initFuncInfos: (funcs) ->
    _array = []
    funcs.forEach (name, ste) ->
      _array.push [name, ste.number]
    _array.sort (x, y) -> x[1] - y[1]
    name: x[0], argc: x[1] for x in _array

  # process local names
  _initLocalNames: (locals) ->
    _localNames = {}
    for own k, v of locals
      _array = []
      v.forEach (name, ste) ->
        _array.push [name, ste.number]
      _array.sort (x, y) -> x[1] - y[1]
      _localNames[k] = (x[0] for x in _array)
    _localNames

  # generate code into current code context
  emit: (bytecode...) -> @_currentCode.push x for x in bytecode

  _getOpName: (opcode) ->
    for name, num of op
      if opcode == num
        return name
    #throw new Error "Invalid opcode #{opcode}"

  dump: ->
    # dump code in global scope
    @_dumpCode @code
    utils.printf '\n'
    # dump user-defined functions
    for i in [0...@functions.length]
      if @functions[i] instanceof UserFunction
        _funcName = @functions[i].name
        utils.printf '%s:\n', _funcName
        @_dumpCode @functions[i].code, @localNames[_funcName]
        utils.printf '\n'

  _dumpCode: (code, localNames = @globalNames) ->
    i = 0
    len = code.length
    while i < len
      opname = @_getOpName code[i]
      utils.printf('%-4d%-10s', i, opname)
      # deal with operand
      switch opname
        when 'LDCONST'
          _const = @constNames[code[++i]]
          if _const.constructor is String
            utils.printf "%d ('%s')", code[i], _const
          else
            utils.printf "%d (%s)", code[i], _const
        when 'LDLOCAL', 'STLOCAL', 'DELLOCAL'
          throw new Error "Invalid local var" if not localNames?
          _local = localNames[code[++i]]
          utils.printf '%d (%s)', code[i], _local
        when 'LDGLOBAL', 'STGLOBAL', 'DELGLOBAL'
          _globalName = @globalNames[code[++i]] 
          utils.printf '%d (%s)', code[i], _globalName
        when 'CALL'
          _funcName = @funcInfos[code[++i]].name
          utils.printf '%d (%s)', code[i], _funcName
        when 'JT', 'JF', 'JMP'
          utils.printf '%d', code[++i]
      utils.printf('\n')
      i++

  reserveSlot: ->
    @emit 0
    @_currentCode.length - 1

  genSlot: -> @_currentCode.length - 1

  patchSlot: (slot, label) -> @_currentCode[slot] = label

  genLabel: -> @genSlot()

  peekLabel: -> @genSlot() + 1
