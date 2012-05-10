op = require './opcodes'
util = require 'util'

# This is the generated code object of our script.
class @CodeObject
  constructor: (consts, globals, funcs, locals) ->
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
    @constNames = x[0] for x in _array

  # process global variables
  _initGlobalNames: (globals) ->
    _array = []
    globals.forEach (name, ste) ->
      _array.push [name, ste.number]
    _array.sort (x, y) -> x[1] - y[1]
    @globalNames = x[0] for x in _array

  # process functions
  _initFuncNames: (funcs) ->
    _array = []
    funcs.forEach (name, ste) ->
      _array.push [name, ste.number]
    _array.sort (x, y) -> x[1] - y[1]
    @funcNames = x[0] for x in _array

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
  emit: (bytecode...) ->
    @currentCode.push(x) for x in bytecode

  _getOpName: (opcode) ->
    for name, num of op
      if opcode == num
        return name
    throw new Error "Invalid opcode #{opcode}"

  dump: ->
    # TODO dump functions
    i = 0
    len = @code.length
    printf = (args...) ->
      process.stdout.write(util.format.apply(null, args))
    while i < len
      opname = @_getOpName @code[i]
      printf '%d\t%s', i, opname
      # deal with operand
      # TODO provide extra info of operand
      if opname in ['LDCONST', 'LDLOCAL', 'LDGLOBAL', 'STLOCAL', 'STGLOBAL', 'CALL', 'JT', 'JF', 'JMP', 'DELLOCAL', 'DELGLOBAL']
          printf '%d\n', ++i
      i++
