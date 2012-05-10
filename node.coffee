# This file contains AST node types and other info.
# Get the constructor for comparing node type.
@getType = (node) -> node.constructor

# All total 24 AST node types
# Node for numeric literals
@NumericLiteral = (@value) ->

# Node for string literals
@StringLiteral = (@value) ->

# Node for null literals
@NullLiteral = ->

# Node for boolean literals
@BooleanLiteral = (@value) ->

# Node for variables
@Variable = (@name) ->

# Node for function calls
@FunctionCall = (@name, args) ->
  @arguments = args

# Node for postfix expressions
@PostfixExpression = (@operator, @expression) ->

# Node for unary expressions
@UnaryExpressions = (@operator, @expression) ->

_binExpression = (ctx, op, l, r) ->
  ctx.operator = op
  ctx.left = l
  ctx.right = r
  return

@BinaryExpression = (op, l, r) ->
  _binExpression this, op, l, r

@ConditionalExpression = (@condition, @trueExpression, @falseExpression) ->

@AssignmentExpression = (op, l, r) ->
  _binExpression this, op, l, r

@Block = (@statements) ->

@VariableStatement = (@declarations) ->

@VariableDeclaration = (@name, @value) ->

@EmptyStatement = ->

@IfStatement = (@condition, @ifStatement, @elseStatement) ->

@DoWhileStatement = (@condition, @statement) ->

@WhileStatement = (@condition, @statement) ->

@ForStatement = (@initializer, @test, @counter, @statement) ->

@ContinueStatement = ->

@BreakStatement = ->

@ReturnStatement = (@value) ->

@Function_ = (@name, @params, @elements) ->

@Program = (@elements) ->

