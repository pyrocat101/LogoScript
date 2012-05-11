ast = require './node'
#symTable = require './symTable'

# This is AST tree visitor base class.
# Subclass this base class for custom visiting methods.
# The visitor method should name like visit<NodeType>.
# The node is passed as an argument into the vistor.
class BaseASTVisitor
  # entry point for visiting nodes
  visitNumericLiteral: (node) ->

  visitStringLiteral: (node) ->

  visitNullLiteral: (node) ->

  visitBooleanLiteral: (node) ->

  visitVariable: (node) ->

  visitFunctionCall: (node) ->

  visitPostfixExpression: (node) ->

  visitUnaryExpression: (node) ->

  visitBinaryExpression: (node) ->

  visitConditionalExpression: (node) ->

  visitAssignmentExpression: (node) ->

  visitBlock: (node) ->

  visitVariableStatement: (node) ->

  visitVariableDeclaration: (node) ->

  visitEmptyStatement: (node) ->

  visitIfStatement: (node) ->

  visitDoWhileStatement: (node) ->

  visitWhileStatement: (node) ->

  visitForStatement: (node) ->

  visitContinueStatement: (node) ->
  
  visitBreakStatement: (node) ->

  visitReturnStatement: (node) ->

  visitFunction_: (node) ->

  visitProgram: (node) ->

  enter: (nodeName, node) ->
    @['enter' + nodeName]?(node)

class @FirstPassVisitor extends BaseASTVisitor
  # In the 1st pass, we construct constant table and 
  # gather symbol information.
  constructor: (@tabSet) ->

  enterFunction_: (node) ->
    # create entry for function
    # FIXME check for redefine
    @tabSet.addLocal node.name
    # create symbol
    @tabSet.funcs.add node.name

  visitNumericLiteral: (node) ->
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
        throw new Error "undefined variable '#{node.name}'"
      # add global variable symbol info
      node.symInfo = @tabSet.globals.get node.name
    # add local variable symbol info
    node.symInfo = @tabSet.currentTab.get node.name

  # TODO change logic to suit new synbol table machanism from here!
  visitFunctionCall: (node) ->
    # check for function name in symbol table
    unless @tabSet.funcs.contains node.name
      #TODO handle error
      throw new Error "undefined function '#{node.name}'"
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
    node.genCode = @gen.genVariable

  visitNumericLiteral: (node) ->
    node.genCode = @gen.genLiteral

  visitStringLiteral: (node) ->
    node.genCode = @gen.genLiteral

  visitNullLiteral: (node) ->
    node.genCode = @gen.genVariable

  visitBooleanLiteral: (node) ->
    node.genCode = @gen.genVariable

  visitFunctionCall: (node) ->
    node.genCode = @gen.genFunctionCall

  visitPostfixExpression: (node) ->
    node.genCode = @gen.genPostfixExpression

  visitUnaryExpression: (node) ->
    node.genCode = @gen.genUnaryExpression

  visitBinaryExpression: (node) ->
    node.genCode = @gen.genBinaryExpression

  visitConditionalExpression: (node) ->
    node.genCode = @gen.genConditionalExpression

  visitAssignmentExpression: (node) ->
    node.genCode = @gen.genAssignmentExpression

  visitBlock: (node) ->
    node.genCode = @gen.genBlock

  visitVariableStatement: (node) ->
    node.genCode = @gen.genVariableStatement

  visitVariableDeclaration: (node) ->
    node.codeGne = @gen.genVariableDeclaration

  visitEmptyStatement: (node) ->
    node.genCode = @gen.genEmptyStatement

  visitIfStatement: (node) ->
    node.genCode = @gen.genIfStatement

  visitDoWhileStatement: (node) ->
    node.genCode = @gen.genDoWhileStatement

  visitWhileStatement: (node) ->
    node.genCode = @gen.genWhileStatement

  visitForStatement: (node) ->
    node.genCode = @gen.genForStatement

  visitContinueStatement: (node) ->
    node.genCode = @gen.genContinueStatement

  visitBreakStatement: (node) ->
    node.genCode = @gen.genBreakStatement

  visitReturnStatement: (node) ->
    node.genCode = @gen.genReturnStatement

  visitFunction_: (node) ->
    node.genCode = @gen.genFunction

  visitProgram: (node) ->
    node.genCode = @gen.genProgram
