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
  # gather symbol information.
  constructor: (@tabSet.consts, @symTable) ->
  constructor: (@tabSet) ->
    @on 'funcDecl', (node) ->
      # create entry for function
      # FIXME check for redefine
      @tabSet.addLocal node.name
      # create symbol
      @tabSet.funcs.add node.name

  visitNumbericLiteral = (node) ->
    node.constNum = @tabSet.consts.put node.value

  visitStringLiteral = (node) ->
    node.constNum = @tabSet.consts.put node.value

  visitNullLiteral = (node) ->
    node.constNum = @tabSet.consts.put node.value

  visitBooleanLiteral = (node) ->
    node.constNum = @tabSet.consts.put node.value

  visitVariable = (node) ->
    # check for local scope, then global scope
    unless @tabSet.currentTab.contains node.name
      unless @tabSet.isGlobal node.name
        throw new Error("undefined variable '" + node.name + '"')
      # add global variable symbol info
      node.symInfo = @tabSet.globals.get node.name
    # add local variable symbol info
    node.symInfo = @tabSet.currentTab.get node.name

  # TODO change logic to suit new synbol table machanism from here!
  visitFunctionCall = (node) ->
    # check for function name in symbol table
    unless @tabSet.funcs.contains node.name
      #TODO handle error
      throw new Error("undefined function '" + node.name + "'")
    # ref to symbol entry
    node.symInfo = @tabSet.funcs.get node.name
  
  visitVariableDeclaration = (node) ->
    unless @tabSet.currentTab.contains node.name
      unless @tabSet.isGlobal node.name
        # declare local variable
        @tabSet.currentTab.add node.name
        node.symInfo = @tabSet.currentTab.get node.name
      node.symInfo = @tabSet.globals.get node.name
    node.symInfo = @tabSet.currentTab.get node.name

  visitFunction = (node) ->
    # exit symbol table entry
    @tabSet.enterGlobal()
