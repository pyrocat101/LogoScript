There are two kinds of functions: built-in functions and user-defined functions.

# LogoFunction

We abstract a class LogoFunction to wrap common properties of two functions:

    class LogoFunction
      constructor: (@name, @argc) ->
      invoke: (args...) ->
        if args.length isnt @argc
        throw new Error "#{@name}() takes exactly #{@argc} arguments (#{args.length} given)"

# Built-in Functions

Built-in functions are created outside of LogoScript source code:

    class BuiltinFunction extends LogoFunction
      constructor: (name, argc, @func) -> super name, argc
      # It is invoked by VM
      invoke: (args...) ->
        super.apply this, args
        # We should bind context of @func in advance.
        return @func.apply(null, args)

# User-defined Functions

As for user-defined functions, their bytecodes are executed by VM.

    class UserFunction extends LogoFunction
      constructor: (name, argc) ->
        super name, argc
        @code = []
      # When invoked by VM, it should pass bytecode to VM
      # We should also bind 'visitor' in advance.
      invoke: (visitor, args...) ->
        super.apply this, args
        visitor @code, args

A visitor is a special function that receive bytecode and arguments of a user-defined function. We define an '_executeUserFunc' in VM, so that user-defined functions can be handled by VM.

# Procedure

Before the first pass, where we analyze symbols, we register built-in functions into function table.

    registerBuiltins: (funcTable, builtins) ->
      for builtin of builtins
        funcTable.add builtin.name, builtin.argc

After first pass, we shall have all functions in the function table, upon which we initialize functions in CodeObject. Then we generate bytecode for user-defined functions, wrap them in UserFunctions and put them into CodeObject.functions.

    _initFunctions: -> @functions = []

    startFuncCode: (funcNum) -> @_currentCode = @functions[funcNum].code
      
    endFunCode: -> @_currentCode = @code

Built-in functions should also be registered into functions.

    addBuiltinFuncs: (builtins) ->
      @functions[i] = builtins[i] for [0...builtins.length]
