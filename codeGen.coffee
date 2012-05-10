op = require './opcodes'
symTable = require './symTable'

@getGenerator = (codeObj) ->
  # In the following code generation functions, 
  # the 'this' object is the current node context.
  # Also, the codeObj indicates the code object to generate
  # code upon.
  gen =
    genVariable: ->
      switch this.symInfo.flag
        when symTable.SYM_LOCAL
          codeObj.emit op.LDLOCAL, this.symInfo.number
        when symTable.SYM_GLOBAL
          codeObj.emit op.LDGLOBAL, this.symInfo.number
        else
          throw new Error "Invalid symbol: #{@name}"

    _genStore: ->
      switch this.symInfo.flag
        when symTable.SYM_LOCAL
          codeObj.emit op.STLOCAL, this.symInfo.number
        when symTable.SYM_GLOBAL
          codeObj.emit op.STGLOBAL, this.symInfo.number
        else
          throw new Error "Invalid symbol: #{@name}"

    genLiteral: ->
      codeObj.emit op.LDCONST, this.constNum

    genFunctionCall: ->
      # TODO gen code for function call

    genPostfixExpression: ->

    genUnaryExpression: ->

    genBinaryExpression: ->
      this.left.genCode()
      this.right.genCode()
      switch this.operator
        when '*' then codeObj.emit op.MUL
        when '/' then codeObj.emit op.DIV
        when '%' then codeObj.emit op.MOD
        when '+' then codeObj.emit op.ADD
        when '-' then codeObj.emit op.SUB
        when '<<' then codeObj.emit op.LSHIFT
        when '>>>' then codeObj.emit op.URSHIFT
        when '>>' then codeObj.emit op.RSHIFT
        when '<=' then codeObj.emit op.LTE
        when '>=' then codeObj.emit op.GTE
        when '<' then codeObj.emit op.LT
        when '>' then codeObj.emit op.GT
        when '==' then codeObj.emit op.EQ
        when '!=' then codeObj.emit op.NEQ
        when '&' then codeObj.emit op.BAND
        when '^' then codeObj.emit op.BXOR
        when '|' then codeObj.emit op.BOR
        when '&&' then codeObj.emit op.AND
        when '||' then codeObj.emit op.OR
        when ',' then codeObj.emit op.ROT, op.POP

    genConditionalExpression: ->

    genAssignmentExpression: ->
      this.left.genCode()
      this.right.genCode()
      switch this.operator
        when '*=' then codeObj.emit op.MUL
        when '/=' then codeObj.emit op.DIV
        when '%=' then codeObj.emit op.MOD
        when '+=' then codeObj.emit op.ADD
        when '-=' then codeObj.emit op.SUB
        when '<<=' then codeObj.emit op.LSHIFT
        when '>>=' then codeObj.emit op.RSHIFT
        when '>>>=' then codeObj.emit op.URSHIFT
        when '&=' then codeObj.emit op.BAND
        when '^=' then codeObj.emit op.BXOR
        when '|=' then codeObj.emit op.BOR
      _genStore.call this.left

    genBlock: ->

    genVariableStatement: ->
      for decl in this.declarations
        decl.genCode()
        codeObj.emit op.POP

    genVariableDeclaration: ->
      this.value.genCode()
      switch this.symInfo.flag
        when symTable.SYM_LOCAL
          codeObj.emit op.STLOCAL, this.symInfo.number
        when symTable.SYM_GLOBAL
          codeObj.emit op.STGLOBAL, this.symInfo.number
        else
          throw new Error "Invalid symbol: #{@name}"

    genEmptyStatement: ->
      # We do nothing

    genIfStatement: ->

    genDoWhileStatement: ->

    genWhileStatement: ->

    genForStatement: ->

    genContinueStatement: ->

    genBreakStatement: ->

    genReturnStatement: ->

    genFunction: ->

    genProgram: ->
      # Program: [element]
      elem.genCode() for elem in this

  return gen
