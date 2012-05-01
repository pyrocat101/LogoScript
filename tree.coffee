ast = require ast
require symTable

# This is AST tree visitor base class.
# Subclass this base class for custom visiting methods.
# The visitor method should name like visit<NodeType>.
# The node is passed as an argument into the vistor.
class BaseASTVisitor
    # entry point for visiting nodes
    dispatch: (node) ->
        # Children-first traverse
        type = ast.getType(node)
        switch type
            when ast.FunctionCall
                @dispatch node.name
                # iterate over all arguments
                @dispatch arg for arg in node.arguments
                @_dispatch type, node
            when ast.PostfixExpression, ast.UnaryExpression
                @dispatch node.expression
                @_dispatch type, node
            when ast.BinaryExpression, ast.AssignmentExpression
                @dispatch node.left
                @dispatch node.right
                @_dispatch type, node
            when ast.ConditionalExpression
                @dispatch node.condition
                @dispatch node.trueExpression
                @dispatch node.falseExpression
                @_dispatch type, node
            when ast.Block
                @dispatch stmt for stmt in node.statements
                @_dispatch type, node
            when ast.VariableStatement
                @dispatch decl for decl in node.declarations
                @_dispatch type, node
            when ast.VariableDeclaration
                @dispatch node.value
                @_dispatch type, node
            when ast.IfStatement
                @dispatch node.condition
                @dispatch node.ifStatement
                @dispatch node.elseStatement
                @_dispatch type, node
            when ast.DoWhileStatement, ast.WhileStatement
                @dispatch node.condition
                @dispatch node.statement
                @_dispatch type, node
            when ast.ForStatement
                @dispatch node.initializer
                @dispatch node.test
                @dispatch node.counter
                @dispatch node.statement
                @_dispatch type, node
            when ast.ReturnStatement
                @dispatch node.value
                @_dispatch type, node
            when ast.Function
                # onFuncDecl event
                @_onfuncDecl?(node)
                # iterate over arguments
                @dispatch param for param in node.params
                @dispatch node.elements
                @_dispatch type, node
            when ast.Program
                @dispatch elem for elem in node.elements
                @_dispatch type, node
            else @_dispatch type, node

    _dispatch: (type, node) ->
        funcName = 'visit' + type.name
        if @[funcName]? then @[funcName](node)

    on: (event, cb, ctx = this) ->
        @['_on' + event] = (obj) ->
            cb.apply(ctx, obj)

class FirstPassVisitor extends BaseASTVisitor
    # in the 1st pass, we construct constant table and 
    # gather basic symbol information.
    constructor: (@constTable, @symTable) ->
        @_currentSte = @symTable
        @on 'funcDecl', (node) ->
            # create entry for function
            # FIXME check for redefine
            funcSte = SymTableEntry()
            @_currentSte.addChild node.name, funcSte
            # create symbol
            @_currentSte.putSymbol node.name, SYM_FUNC
            # switch current symbol entry
            @_currentSte = funcSte

    visitNumbericLiteral = (node) -> @constTable.putConst node.value

    visitStringLiteral = (node) -> @constTable.putConst node.value

    visitNullLiteral = (node) -> @constTable.putConst node.value

    visitBooleanLiteral = (node) -> @constTable.putConst node.value

    visitVariable = (node) ->
        unless @_currentSte.containsSymbol node.name
            flag = SYM_NONE
            # check whether var is in current scope
            if @_currentSte.isLocal node.name then flag =  SYM_LOCAL
            @_currentSte.putSymbol node.name, flag

    visitFunctionCall = (node) ->
        unless @_currentSte.containsSymbol node.name
            @_currentSte.putSymbol node.name, SYM_NONE
    
    visitVariableDeclaration = (node) ->
        # if this is the root scope, then we set this var as local.
        flag = SYM_NONE
        if @_currentSte == @_currentSte.root then flag = SYM_LOCAL
        @_currentSte.putSymbol node.name, flag

    visitFunction = (node) ->
        # exit symbol table entry
        @_currentSte = @_currentSte.parent
