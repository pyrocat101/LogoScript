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
      @codeObj.currentCode[slot] = label

  patchBreak: (label) ->
    throw new Error 'No scope in chain' if @_chain.length < 1
    top = @_chain[@_chain.length - 1]
    top.breakSlots.forEach (slot) =>
      @codeObj.currentCode[slot] = label

  addBreakSlot: (slot) ->
    top = @_chain[@_chain.length - 1]
    top.breakSlots.push slot

  addContinueSlot: (slot) ->
    top = @_chain[@_chain.length - 1]
    top.continueSlots.push slot

# This is the generated code object of our script.
class @CodeObject
  constructor: (consts, globals, funcs, locals) ->
    @scopes = new ScopeChain(this)
    @code = []
    @_initFuncCodes funcs.count
    # current generate context is @code
    @currentCode = @code
    # init names
    @_initConsts consts
    @_initGlobalNames globals
    @_initFuncNames funcs
    @_initLocalNames locals

  # init func codes
  _initFuncCodes: (count) ->
    @funcs = [] for x in count
   
  # process constant table
  _initConsts: (consts) ->
    _array = []
    consts.forEach (obj, nr) ->
      _array.push [obj, nr]
    _array.sort (x, y) -> x[1] - y[1]
    @constNames = (x[0] for x in _array)

  # process global variables
  _initGlobalNames: (globals) ->
    _array = []
    globals.forEach (name, ste) ->
      _array.push [name, ste.number]
    _array.sort (x, y) -> x[1] - y[1]
    @globalNames = (x[0] for x in _array)

  # process functions
  _initFuncNames: (funcs) ->
    _array = []
    funcs.forEach (name, ste) ->
      _array.push [name, ste.number]
    _array.sort (x, y) -> x[1] - y[1]
    @funcNames = (x[0] for x in _array)

  # process local names
  _initLocalNames: (locals) ->
    _array = []
    @localNames = {}
    for own k, v in locals
      v.forEach (name, ste) ->
        _array.push [name, ste.number]
      _array.sort (x, y) -> x[1] - y[1]
      @localNames[k] = x[0] for x in _array
      _array.clear()

  # generate code into current code context
  emit: (bytecode...) -> @currentCode.push x for x in bytecode

  _getOpName: (opcode) ->
    for name, num of op
      if opcode == num
        return name
    #throw new Error "Invalid opcode #{opcode}"

  dump: ->
    # TODO dump functions
    i = 0
    len = @code.length
    while i < len
      opname = @_getOpName @code[i]
      utils.printf('%-4d%-10s', i, opname)
      # deal with operand
      # TODO provide extra info of operand
      if opname in ['LDCONST', 'LDLOCAL', 'LDGLOBAL', 'STLOCAL', 'STGLOBAL', 'CALL', 'JT', 'JF', 'JMP', 'DELLOCAL', 'DELGLOBAL']
        utils.printf('%d\n', @code[++i])
      else
        utils.printf('\n')
      i++

  reserveSlot: ->
    ret = @currentCode.length
    @emit 0
    ret

  genSlot: -> @currentCode.length - 1

  patchSlot: (slot, label) -> @currentCode[slot] = label

  genLabel: -> @genSlot()

  peekLabel: -> @genSlot() + 1
