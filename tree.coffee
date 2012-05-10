ast = require './node'
#symTable = require './symTable'

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

class @FirstPassVisitor extends BaseASTVisitor
  # In the 1st pass, we construct constant table and 
  # gather symbol information.
  constructor: (@tabSet) ->
    @on 'funcDecl', (node) ->
      # create entry for function
      # FIXME check for redefine
      @tabSet.addLocal node.name
      # create symbol
      @tabSet.funcs.add node.name

  visitNumbericLiteral: (node) ->
    node.constNum = @tabSet.consts.put node.value

  visitStringLiteral: (node) ->
    node.constNum = @tabSet.consts.put node.value

  visitNullLiteral: (node) ->
    node.constNum = @tabSet.consts.put node.value

  visitBooleanLiteral: (node) ->
    node.constNum = @tabSet.consts.put node.value

  visitVariable: (node) ->
    # check for local scope, then global scope
    unless @tabSet.currentTab.contains node.name
      unless @tabSet.isGlobal node.name
        throw new Error("undefined variable '" + node.name + '"')
      # add global variable symbol info
      node.symInfo = @tabSet.globals.get node.name
    # add local variable symbol info
    node.symInfo = @tabSet.currentTab.get node.name

  # TODO change logic to suit new synbol table machanism from here!
  visitFunctionCall: (node) ->
    # check for function name in symbol table
    unless @tabSet.funcs.contains node.name
      #TODO handle error
      throw new Error("undefined function '" + node.name + "'")
    # ref to symbol entry
    node.symInfo = @tabSet.funcs.get node.name
  
  visitVariableDeclaration: (node) ->
    unless @tabSet.currentTab.contains node.name
      unless @tabSet.isGlobal node.name
        # declare local variable
        @tabSet.currentTab.add node.name
        node.symInfo = @tabSet.currentTab.get node.name
      node.symInfo = @tabSet.globals.get node.name
    node.symInfo = @tabSet.currentTab.get node.name

  visitFunction_: (node) ->
    # exit symbol table entry
    @tabSet.enterGlobal()

class @SecondPassVisitor extends BaseASTVisitor
  # In the 2nd pass, we assign code generator to nodes.
  constructor: (@gen) ->

  visitVariable: (node) ->
    node.codeGen = @gen.genVariable

  visitNumbericLiteral: (node) ->
    node.codeGen = @gen.genLiteral

  visitStringLiteral: (node) ->
    node.codeGen = @gen.genLiteral

  visitNullLiteral: (node) ->
    node.codeGen = @gen.genVariable

  visitBooleanLiteral: (node) ->
    node.codeGen = @gen.genVariable

  visitFunctionCall: (node) ->
    node.codeGen = @gen.genFunctionCall

  visitPostfixExpression: (node) ->
    node.codeGen = @gen.genPostfixExpression

  visitUnaryExpression: (node) ->
    node.codeGen = @gen.genUnaryExpression

  visitBinaryExpression: (node) ->
    node.codeGen = @gen.genBinaryExpression

  visitConditionalExpression: (node) ->
    node.codeGen = @gen.genConditionalExpression

  visitAssignmentExpression: (node) ->
    node.codeGen = @gen.genAssignmentExpression

  visitBlock: (node) ->
    node.codeGen = @gen.genBlock

  visitVariableStatement: (node) ->
    node.codeGen = @gen.genVariableStatement

  visitVariableDeclaration: (node) ->
    node.codeGne = @gen.genVariableDeclaration

  visitEmptyStatement: (node) ->
    node.codeGen = @gen.genEmptyStatement

  visitIfStatement: (node) ->
    node.codeGen = @gen.genIfStatement

  visitDoWhileStatement: (node) ->
    node.codeGen = @gen.genDoWhileStatement

  visitWhileStatement: (node) ->
    node.codeGen = @gen.genWhileStatement

  visitForStatement: (node) ->
    node.codeGen = @gen.genForStatement

  visitContinueStatement: (node) ->
    node.codeGen = @gen.genContinueStatement

  visitBreakStatement: (node) ->
    node.codeGen = @gen.genBreakStatement

  visitReturnStatement: (node) ->
    node.codeGen = @gen.genReturnStatement

  visitFunction_: (node) ->
    node.codeGen = @gen.genFunction

  genProgram: (node) ->
    node.codeGen = @gen.genProgram
