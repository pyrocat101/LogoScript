# All total 24 AST node types
# Node for numeric literals
class @NumericLiteral
  constructor: (@value) ->
  accept: (visitor) ->
    visitor.visitNumericLiteral this

# Node for string literals
class @StringLiteral
  constructor: (@value) ->
  accept: (visitor) -> visitor.visitStringLiteral this

# Node for null literals
class @NullLiteral
  accept: (visitor) -> visitor.visitNullLiteral this

# Node for boolean literals
class @BooleanLiteral
  constructor: (@value) ->
  accept: (visitor) -> visitor.visitBooleanLiteral this

# Node for variables
class @Variable
  constructor: (@name) ->
  accept: (visitor) -> visitor.visitVariable this

# Node for function calls
class @FunctionCall
  constructor: (@name, args) -> @arguments = args
  accept: (visitor) ->
    @name.accept visitor
    arg.accept visitor for arg in @arguments
    visitor.visitFunctionCall this

# Node for postfix expressions
class @PostfixExpression
  constructor: (@operator, @expression) ->
  accept: (visitor) ->
    @expression.accept visitor
    visitor.visitPostfixExpression this

# Node for unary expressions
class @UnaryExpression
  constructor: (@operator, @expression) ->
  accept: (visitor) ->
    @expression.accept visitor
    visitor.visitUnaryExpression this

_binExpression = (ctx, op, l, r) ->
  ctx.operator = op
  ctx.left = l
  ctx.right = r
  return

class @BinaryExpression
  constructor: (op, l, r) -> _binExpression this, op, l, r
  accept: (visitor) ->
    @left.accept visitor
    @right.accept visitor
    visitor.visitBinaryExpression this

class @ConditionalExpression
  constructor: (@condition, @trueExpression, @falseExpression) ->
  accept: (visitor) ->
    @condition.accept visitor
    @trueExpression.accept visitor
    @falseExpression.accept visitor
    visitor.visitConditionalExpression this

class @AssignmentExpression
  constructor: (op, l, r) -> _binExpression this, op, l, r
  accept: (visitor) ->
    @left.accept visitor
    @right.accept visitor
    visitor.visitAssignmentExpression this

class @Block
  constructor: (@statements) ->
  accept: (visitor) ->
    stmt.accept visitor for stmt in @statements
    visitor.visitBlock this

class @VariableStatement
  constructor: (@declarations) ->
  accept: (visitor) ->
    decl.accept visitor for decl in @declarations
    visitor.visitVariableStatement this

class @VariableDeclaration
  constructor: (@name, @value) ->
  accept: (visitor) ->
    @value.accept visitor
    visitor.visitVariableDeclaration this

class @EmptyStatement
  accept: (visitor) -> visitor.visitEmptyStatement this

class @IfStatement
  constructor: (@condition, @ifStatement, @elseStatement) ->
  accept: (visitor) ->
    @condition.accept visitor
    @ifStatement.accept visitor
    @elseStatement.accept visitor
    visitor.visitIfStatement this

class @DoWhileStatement
  constructor: (@condition, @statement) ->
  accept: (visitor) ->
    @condition.accept visitor
    @statement.accept visitor
    visitor.visitDoWhileStatement this

class @WhileStatement
  constructor: (@condition, @statement) ->
  accept: (visitor) ->
    @condition.accept visitor
    @statement.accept visitor
    visitor.visitWhileStatement this

class @ForStatement
  constructor: (@initializer, @test, @counter, @statement) ->
  accept: (visitor) ->
    @initializer.accept visitor
    @test.accept visitor
    @counter.accept visitor
    @statements.accept visitor
    visitor.visitForStatement this

class @ContinueStatement
  accept: (visitor) -> visitor.visitContinueStatement this

class @BreakStatement
  accept: (visitor) -> visitor.visitBreakStatement this

class @ReturnStatement
  constructor: (@value) ->
  accept: (visitor) ->
    @value.accept visitor
    visitor.visitReturnStatement this

class @Function_
  constructor: (@name, @params, @elements) ->
  accept: (visitor) ->
    visitor.enter 'Function_', this
    param.accept visitor for param in @params
    @elements.accept visitor
    visitor.visitFunction_ this

class @Program
  constructor: (@elements) ->
  accept: (visitor) ->
    elem.accept visitor for elem in @elements
    visitor.visitProgram this

