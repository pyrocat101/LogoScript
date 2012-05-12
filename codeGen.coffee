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
      this.expression.genCode()
      codeObj.emit op.DUP
      switch this.operator
        when '++' then codeObj.emit op.INC
        when '--' then codeObj.emit op.DEC
      _genStore.call this.expression

    genUnaryExpression: ->
      this.expression.genCode()
      if this.operator == 'delete' and this.expression.symInfo?
        switch this.symInfo.flag
          when symTable.SYM_LOCAL
            codeObj.emit op.DELLOCAL, this.symInfo.number
          when symTable.SYM_GLOBAL
            codeObj.emit op.DELGLOBAL, this.symInfo.number
          else
            throw new Error "Invalid symbol: #{@name}"
      else
        switch this.operator
          when '++' then codeObj.emit op.INC
          when '--' then codeObj.emit op.DEC
          when '+' then codeObj.emit op.POS
          when '-' then codeObj.emit op.NEG
          when '~' then codeObj.emit op.BNEG
          when '!' then codeObj.emit op.NOT
          when 'typeof' then codeObj.emit op.TYPEOF

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
      # Block: [statement]
      for stmt in this.statements
        stmt.genCode()
        codeObj.emit op.POP if stmt.leaveResult?

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
      codeObj.emit op.JT, label1
      label3 = codeObj.peekLabel()

      # patch continue and break
      codeObj.scopes.patchContinue label2
      codeObj.scopes.patchBreak label3

      codeObj.scopes.popScope()

    genWhileStatement: ->
      codeObj.scopes.pushScope()
      
      label1 = codeObj.peekLabel()
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
      label1 = codeObj.reserveSlot()

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
      codeObj.patchContinue label2
      codeObj.patchBreak label3

      codeObj.scopes.popScope()

    genContinueStatement: ->
      codeObj.emit op.JMP
      codeObj.scopes.addContinueSlot codeObj.reserveSlot()

    genBreakStatement: ->
      codeObj.emit op.JMP
      codeObj.scopes.addBreakSlot codeObj.reserveSlot()

    genReturnStatement: ->
      codeObj.emit op.RET

    genFunction: ->

    genProgram: ->
      # Program: [element]
      for elem in this.elements
        elem.genCode()
        codeObj.emit op.POP if elem.leaveResult?

  return gen
