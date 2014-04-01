op = require './opcodes'
symTable = require './symTable'

_genStore = (codeObj) ->
  switch @symInfo.flag
    when symTable.SYM_LOCAL
      codeObj.emit op.STLOCAL, @symInfo.number
    when symTable.SYM_GLOBAL
      codeObj.emit op.STGLOBAL, @symInfo.number
    else
      throw new Error "Invalid symbol: #{@name}"

@getGenerator = (codeObj) ->
  # In the following code generation functions,
  # the 'this' object is the current node context.
  # Also, the codeObj indicates the code object to generate
  # code upon.
  gen =
    genVariable: ->
      switch @symInfo.flag
        when symTable.SYM_LOCAL
          codeObj.emit op.LDLOCAL, @symInfo.number
        when symTable.SYM_GLOBAL
          codeObj.emit op.LDGLOBAL, @symInfo.number
        else
          throw new Error "Invalid symbol: #{@name}"

    genLiteral: ->
      codeObj.emit op.LDCONST, @constNum

    genFunctionCall: ->
      # arguments are pushed onto stack from RTL
      arg.genCode() for arg in @arguments.reverse()
      codeObj.emit op.CALL, @symInfo.number

    genPostfixExpression: ->
      @expression.genCode()
      codeObj.emit op.DUP
      switch @operator
        when '++' then codeObj.emit op.INC
        when '--' then codeObj.emit op.DEC
      _genStore.call @expression, codeObj
      codeObj.emit op.POP

    genUnaryExpression: ->
      @expression.genCode()
      if @operator == 'delete' and @expression.symInfo?
        switch @symInfo.flag
          when symTable.SYM_LOCAL
            codeObj.emit op.DELLOCAL, @symInfo.number
          when symTable.SYM_GLOBAL
            codeObj.emit op.DELGLOBAL, @symInfo.number
          else
            throw new Error "Invalid symbol: #{@name}"
      else
        switch @operator
          when '++' then codeObj.emit op.INC
          when '--' then codeObj.emit op.DEC
          when '+' then codeObj.emit op.POS
          when '-' then codeObj.emit op.NEG
          when '~' then codeObj.emit op.BNEG
          when '!' then codeObj.emit op.NOT
          when 'typeof' then codeObj.emit op.TYPEOF

    genBinaryExpression: ->
      @left.genCode()
      @right.genCode()
      switch @operator
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
      @condition.genCode()
      codeObj.emit op.JF
      slot1 = codeObj.reserveSlot()
      @trueExpression.genCode()
      #codeObj.emit op.POP if @ifStatement.leaveResult?

      codeObj.emit op.JMP
      slot2 = codeObj.reserveSlot()
      codeObj.patchSlot slot1, codeObj.peekLabel()

      @falseExpression.genCode()
      #codeObj.emit op.POP if @elseStatement.leaveResult?
      codeObj.patchSlot slot2, codeObj.peekLabel()

    genAssignmentExpression: ->
      @left.genCode()
      @right.genCode()
      switch @operator
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
      _genStore.call @left, codeObj

    genBlock: ->
      # Block: [statement]
      for stmt in @statements
        stmt.genCode()
        codeObj.emit op.POP if stmt.leaveResult?

    genVariableStatement: ->
      for decl in @declarations.splice 0, @declarations.length - 1
        decl.genCode()
        codeObj.emit op.POP
      @declarations[@declarations.length - 1].genCode()

    genVariableDeclaration: ->
      @value.genCode()
      switch @symInfo.flag
        when symTable.SYM_LOCAL
          codeObj.emit op.STLOCAL, @symInfo.number
        when symTable.SYM_GLOBAL
          codeObj.emit op.STGLOBAL, @symInfo.number
        else
          throw new Error "Invalid symbol: #{@name}"

    genEmptyStatement: ->
      # We do nothing

    genIfStatement: ->
      # if (cond) { trueExp; }
      # ==>
      #         cond
      #         JF label1
      #         trueExp (pop)
      # label1: ...
      # if (cond) {
      #   trueExpl;
      # } else {
      #   falseExp;
      # }
      # ==>
      #         cond
      #         JF label1
      #         trueExp (pop)
      #         JMP label2
      # label1: falseExp (pop)
      # label2: ...
      @condition.genCode()
      codeObj.emit op.JF
      slot1 = codeObj.reserveSlot()
      @ifStatement.genCode()
      codeObj.emit op.POP if @ifStatement.leaveResult?
      # if-else
      if @elseStatement?
        codeObj.emit op.JMP
        slot2 = codeObj.reserveSlot()
      codeObj.patchSlot slot1, codeObj.peekLabel()
      if @elseStatement?
        @elseStatement.genCode()
        codeObj.emit op.POP if @elseStatement.leaveResult?
        codeObj.patchSlot slot2, codeObj.peekLabel()

    genDoWhileStatement: ->
      codeObj.scopes.pushScope()

      label1 = codeObj.peekLabel()
      @statement.genCode()
      codeObj.emit op.POP if @statement.leaveResult?

      label2 = codeObj.peekLabel()
      @condition.genCode()
      codeObj.emit op.JT, label1

      label3 = codeObj.peekLabel()

      # patch continue and break
      codeObj.scopes.patchContinue label2
      codeObj.scopes.patchBreak label3

      codeObj.scopes.popScope()

    genWhileStatement: ->
      codeObj.scopes.pushScope()

      label1 = codeObj.peekLabel()
      @condition.genCode()
      codeObj.emit op.JF
      slot2 = codeObj.reserveSlot()

      @statement.genCode()
      codeObj.emit op.POP if @statement.leaveResult?
      codeObj.emit op.JMP, label1

      label2 = codeObj.peekLabel()
      codeObj.patchSlot slot2, label2

      # patch continue and break
      codeObj.scopes.patchContinue label1
      codeObj.scopes.patchBreak label2

      codeObj.scopes.popScope()

    genForStatement: ->
      codeObj.scopes.pushScope()

      if @initializer?
        @initializer.genCode()
        codeObj.emit op.POP if @initializer.leaveResult?
      label1 = codeObj.peekLabel()

      if @test?
        @test.genCode()
        codeObj.emit op.JF
        slot3 = codeObj.reserveSlot()

      @statement.genCode()
      codeObj.emit op.POP if @statement.leaveResult?

      label2 = codeObj.peekLabel()
      if @counter?
        @counter.genCode()
        codeObj.emit op.POP if @counter.leaveResult?
      codeObj.emit op.JMP, label1

      label3 = codeObj.peekLabel()

      # back patch
      codeObj.patchSlot slot3, label3 if @test?
      codeObj.scopes.patchContinue label2
      codeObj.scopes.patchBreak label3

      codeObj.scopes.popScope()

    genContinueStatement: ->
      codeObj.emit op.JMP
      codeObj.scopes.addContinueSlot codeObj.reserveSlot()

    genBreakStatement: ->
      codeObj.emit op.JMP
      codeObj.scopes.addBreakSlot codeObj.reserveSlot()

    genReturnStatement: ->
      if @value?
        @value.genCode()
        codeObj.emit op.RET
      else
        codeObj.emit op.NRET

    genFunction: ->
      codeObj.startFuncCode @symInfo.number
      for elem in @elements
        elem.genCode()
        codeObj.emit op.POP if elem.leaveResult?
      # In case that our function doesn't return anything,
      # VM will leave an 'undefined' on the stack.
      # So we don't have take care of it here.
      codeObj.endFuncCode()

    genProgram: ->
      # Program: [element]
      for elem in @elements
        elem.genCode()
        codeObj.emit op.POP if elem.leaveResult?

  return gen
