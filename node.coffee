# This file contains AST node types and other info.
# Get the constructor for comparing node type.
@getType = (node) -> node.constructor

# check type and set property for context
_setProperty = (ctx, name, val, typeCtor) ->
    if val.constructor == typeCtor
        ctx[name] = val
    else
        throw new Error 'expecting #{typeCtor.name} for #{name}, but get #{val.constructor.name}'

# All total 24 AST node types
# Node for numeric literals
@NumericLiteral = (value) ->
    _setProperty this, 'value', value, Number

# Node for string literals
@StringLiteral = (value) -> 
    _setProperty this, 'value', value, String

# Node for null literals
@NullLiteral = ->

# Node for boolean literals
@BooleanLiteral = (value) -> 
    _setProperty this, 'value', value, Boolean

# Node for variables
@Variable = (name) -> 
    _setProperty this, 'name', name, String

# Node for function calls
@FunctionCall = (name, args) ->
    _setProperty this, 'name', name, String
    _setProperty this, 'arguments', args, Array

# Node for postfix expressions
@PostfixExpression = (op, expression) ->
    _setProperty this, 'operator', op, String
    _setProperty this, 'expression', op, Object

# Node for unary expressions
@UnaryExpressions = (op, expression) ->
    _setProperty this, 'operator', op, String
    _setProperty this, 'expression', op, Object

_binExpression = (ctx, op, l, r) ->
    _setProperty ctx, 'operator', op, String
    _setProperty ctx, 'left', l, Object
    _setProperty ctx, 'right', r, Object

@BinaryExpression = (op, l, r) ->
    _binExpression this, op, l, r

@ConditionalExpression = (cond, te, fe) ->
    _setProperty this, 'condition', cond, Object
    _setProperty this, 'trueExpression', te, Object
    _setProperty this, 'falseExpression', fe, Object

@AssignmentExpression = (op, l, r) ->
    _binExpression this, op, l, r

@Block = (stmt) ->
    _setProperty this, 'statements', stmt, Array

@VariableStatement = (decls) ->
    _setProperty this, 'declarations', decls, Array

@VariableDeclaration = (name, value) ->
    _setProperty this, 'name', name, String
    _setProperty this, 'value', value, Object

@EmptyStatement = ->

@IfStatement = (cond, ifStmt, elseStmt) ->
    _setProperty this, 'condition', cond, Object
    _setProperty this, 'ifStatement', ifStmt, Object
    _setProperty this, 'elseStatement', elseStmt, Object

@DoWhileStatement = (cond, stmt) ->
    _setProperty this, 'condition', cond, Object
    _setProperty this, 'statement', stmt, Object

@WhileStatement = (cond, stmt) ->
    _setProperty this, 'condition', cond, Object
    _setProperty this, 'statement', stmt, Object

@ForStatement = (init, test, counter, stmt) ->
    _setProperty this, 'initializer', init, Object
    _setProperty this, 'test', test, Object
    _setProperty this, 'counter', counter, Object
    _setProperty this, 'statement', stmt, Object

@ContinueStatement = ->

@BreakStatement = ->

@ReturnStatement = (value) ->
    _setProperty this, 'value', value, Object

@Function_ = (name, params, elems) ->
    _setProperty this, 'name', name, String
    _setProperty this, 'params', params, Array
    _setProperty this, 'elements', elems, Object

@Program = (elems) ->
    _setProperty this, 'elements', elems, Array
