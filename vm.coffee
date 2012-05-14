op = require './opcodes'
BuiltinFunction = require('./codeObj').BuiltinFunction
UserFunction = require('./codeObj').UserFunction

class LogoVM
  constructor: (@codeObj) ->
    # A few shortcuts
    @consts = @codeObj.consts
    @globals = @_initGlobals()

  _initGlobals: ->
    undefined for i in [0...@codeObj.globalNames.length]

  run: -> @_run @codeObj.code

  _run: (code, localContext = @globals, funcName) ->
    stack = []
    pc = 0
    len = code.length
    while pc < len
      switch code[pc]
        when op.HALT then return 0
        when op.POP then stack.pop()
        when op.LDCONST then stack.push @consts[code[++pc]]
        when op.LDLOCAL
          _local = localContext[code[++pc]]
          if typeof _local == 'undefined'
            _name = @codeObj.localNames[funcName][code[pc]]
            throw new Error "#{_name} is not defined"
          stack.push _local
        when op.LDGLOBAL
          _global = @globals[code[++pc]]
          if typeof _global == 'undefined'
            _name = @codeObj.globalNames[code[pc]]
            throw new Error "#{_name} is not defined"
          stack.push _global
        when op.STLOCAL
          localContext[code[++pc]] = stack[stack.length - 1]
        when op.STGLOBAL
          @globals[code[++pc]] = stack[stack.length - 1]
        when op.CALL
          _func = @codeObj.functions[code[++pc]]
          # copy arguments
          _args = (stack.pop() for i in [0..._func.argc])
          if _func instanceof BuiltinFunction
            # invoke function & leave return value on stack.
            stack.push _func.invoke _args    
          else if _func instanceof UserFunction
            _callee = @codeObj.funcInfos[code[pc]].name
            _func.invoke ((code, args) =>
              # create local context
              # TODO cache!
              _localContext = []
              for i in [0...@codeObj.localNames[_callee].length]
                _localContext.push undefined
              # copy arguments into local context
              _localContext[0..._func.argc] = args
              stack.push @_run code, _localContext, _callee
            ), _args
        when op.RET then return stack.pop()
        when op.JT
          if stack.pop() then pc = code[++pc] else ++pc
        when op.JF
          unless stack.pop() then pc = code[++pc] else ++pc
        when op.JMP then pc = code[++pc]
        when op.ADD
          _x = stack.pop()
          _y = stack.pop()
          stack.push _x + _y
        when op.SUB
          _x = stack.pop()
          _y = stack.pop()
          stack.push _x - _y
        when op.MUL
          _x = stack.pop()
          _y = stack.pop()
          stack.push _x * _y
        when op.DIV
          # x / 0 = Infinity
          _x = stack.pop()
          _y = stack.pop()
          stack.push _x / _y
        when op.MOD
          _x = stack.pop()
          _y = stack.pop()
          stack.push _x % _y
        when op.DELLOCAL
          delete localContext[code[++pc]]
        when op.DELGLOBAL
          delete @globals[code[++pc]]
          # delete is always successful
          stack.push true
        when op.INC then ++stack[stack.length - 1]
        when op.DEC then --stack[stack.length - 1]
        when op.POS
          stack[stack.length - 1] = +(stack[stack.length - 1])
        when op.NEG
          stack[stack.length - 1] = -(stack[stack.length - 1])
        when op.LSHIFT
          _x = stack.pop()
          _y = stack.pop()
          stack.push _x << _y
        when op.URSHIFT
          _x = stack.pop()
          _y = stack.pop()
          stack.push _x >>> _y
        when op.RSHIFT
          _x = stack.pop()
          _y = stack.pop()
          stack.push _x >> _y
        when op.LTE
          _x = stack.pop()
          _y = stack.pop()
          stack.push _x <= _y
        when op.GTE
          _x = stack.pop()
          _y = stack.pop()
          stack.push _x >= _y
        when op.LT
          _x = stack.pop()
          _y = stack.pop()
          stack.push _x < _y
        when op.GT
          _x = stack.pop()
          _y = stack.pop()
          stack.push _x > _y
        when op.EQ
          _x = stack.pop()
          _y = stack.pop()
          stack.push _x == _y
        when op.NEQ
          _x = stack.pop()
          _y = stack.pop()
          stack.push _x != _y
        when op.NOT
          stack[stack.length - 1] = !(stack[stack.length - 1])
        when op.BNEG
          stack[stack.length - 1] = ~(stack[stack.length - 1])
        when op.BAND
          _x = stack.pop()
          _y = stack.pop()
          stack.push _x & _y
        when op.BXOR
          _x = stack.pop()
          _y = stack.pop()
          stack.push _x ^ _y
        when op.BOR
          _x = stack.pop()
          _y = stack.pop()
          stack.push _x | _y
        when op.AND
          _x = stack.pop()
          _y = stack.pop()
          stack.push _x && _y
        when op.OR
          _x = stack.pop()
          _y = stack.pop()
          stack.push _x || _y
        when op.ROT
          _x = stack.pop()
          _y = stack.pop()
          stack.push _x
          stack.push _y
        when op.DUP
          # Since values on the stack are not reference,
          # we can simply duplicate it.
          stack.push stack[stack.length - 1]
        when op.TYPEOF then stack.push typeof stack.pop
        when op.NRET then return undefined
        else throw new Error "Invalid opcode #{code[pc]}"
      pc++

    return 0
          
@LogoVM = LogoVM
