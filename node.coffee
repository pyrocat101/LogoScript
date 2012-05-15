Mixins = require('./utils').Mixins

leaveResult =
  leaveResult: true

# All total 24 AST node types
# Node for numeric literals
class @NumericLiteral extends Mixins
  @include leaveResult
  constructor: (@value) ->
  accept: (visitor) ->
    visitor.visitNumericLiteral this

# Node for string literals
class @StringLiteral extends Mixins
  @include leaveResult
  constructor: (@value) ->
  accept: (visitor) -> visitor.visitStringLiteral this

# Node for null literals
class @NullLiteral extends Mixins
  @include leaveResult
  accept: (visitor) -> visitor.visitNullLiteral this

# Node for boolean literals
class @BooleanLiteral extends Mixins
  @include leaveResult
  constructor: (@value) ->
  accept: (visitor) -> visitor.visitBooleanLiteral this

# Node for variables
class @Variable extends Mixins
  @include leaveResult
  constructor: (@name) ->
  accept: (visitor) -> visitor.visitVariable this

# Node for function calls
class @FunctionCall extends Mixins
  @include leaveResult
  constructor: (@name, args) -> @arguments = args
  accept: (visitor) ->
    arg.accept visitor for arg in @arguments
    visitor.visitFunctionCall this

# Node for postfix expressions
class @PostfixExpression extends Mixins
  @include leaveResult
  constructor: (@operator, @expression) ->
  accept: (visitor) ->
    @expression.accept visitor
    visitor.visitPostfixExpression this

# Node for unary expressions
class @UnaryExpression extends Mixins
  @include leaveResult
  constructor: (@operator, @expression) ->
  accept: (visitor) ->
    @expression.accept visitor
    visitor.visitUnaryExpression this

_binExpression = (ctx, op, l, r) ->
  ctx.operator = op
  ctx.left = l
  ctx.right = r
  return

class @BinaryExpression extends Mixins
  @include leaveResult
  constructor: (op, l, r) -> _binExpression this, op, l, r
  accept: (visitor) ->
    @left.accept visitor
    @right.accept visitor
    visitor.visitBinaryExpression this

class @ConditionalExpression extends Mixins
  @include leaveResult
  constructor: (@condition, @trueExpression, @falseExpression) ->
  accept: (visitor) ->
    @condition.accept visitor
    @trueExpression.accept visitor
    @falseExpression.accept visitor
    visitor.visitConditionalExpression this

class @AssignmentExpression extends Mixins
  @include leaveResult
  constructor: (op, l, r) -> _binExpression this, op, l, r
  accept: (visitor) ->
    @left.accept visitor
    @right.accept visitor
    visitor.visitAssignmentExpression this

class @Block extends Mixins
  constructor: (@statements) ->
  accept: (visitor) ->
    stmt.accept visitor for stmt in @statements
    visitor.visitBlock this

class @VariableStatement extends Mixins
  @include leaveResult
  constructor: (@declarations) ->
  accept: (visitor) ->
    decl.accept visitor for decl in @declarations
    visitor.visitVariableStatement this

class @VariableDeclaration extends Mixins
  @include leaveResult
  constructor: (@name, @value) ->
  accept: (visitor) ->
    @value.accept visitor
    visitor.visitVariableDeclaration this

class @EmptyStatement extends Mixins
  accept: (visitor) -> visitor.visitEmptyStatement this

class @IfStatement extends Mixins
  constructor: (@condition, @ifStatement, @elseStatement) ->
  accept: (visitor) ->
    @condition.accept visitor
    @ifStatement.accept visitor
    @elseStatement?.accept visitor
    visitor.visitIfStatement this

class @DoWhileStatement extends Mixins
  constructor: (@condition, @statement) ->
  accept: (visitor) ->
    @condition.accept visitor
    @statement.accept visitor
    visitor.visitDoWhileStatement this

class @WhileStatement extends Mixins
  constructor: (@condition, @statement) ->
  accept: (visitor) ->
    @condition.accept visitor
    @statement.accept visitor
    visitor.visitWhileStatement this

class @ForStatement extends Mixins
  constructor: (@initializer, @test, @counter, @statement) ->
  accept: (visitor) ->
    @initializer?.accept visitor
    @test?.accept visitor
    @counter?.accept visitor
    @statement.accept visitor
    visitor.visitForStatement this

class @ContinueStatement extends Mixins
  accept: (visitor) -> visitor.visitContinueStatement this

class @BreakStatement extends Mixins
  accept: (visitor) -> visitor.visitBreakStatement this

class @ReturnStatement extends Mixins
  constructor: (@value) ->
  accept: (visitor) ->
    @value?.accept visitor
    visitor.visitReturnStatement this

class @Function_ extends Mixins
  constructor: (@name, @params, @elements) ->
  accept: (visitor) ->
    # trigger enterFunction event
    visitor.enter 'Function_', this
    # @params is just an array of names
    # Therefore, we visit parameters directly.
    visitor.visitParameters @params
    elem.accept visitor for elem in @elements
    visitor.visitFunction_ this

class @Program extends Mixins
  constructor: (@elements) ->
  accept: (visitor) ->
    elem.accept visitor for elem in @elements
    visitor.visitProgram this

