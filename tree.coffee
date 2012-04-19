ast = require node

# This is AST tree visitor base class.
# Subclass this base class for custom visiting methods.
# The visitor method should name like visit<NodeType>.
# The node is passed as an argument into the vistor.
class BaseASTVisitor
    # entry point for visiting nodes
    dispatch: (root) ->
        # Children-first traverse
        # TODO check for methods, dispatch visitors

class FirstPassVisitor extends BaseASTVisitor
    # in the 1st pass, we construct constant table and 
    # gather basic symbol information.
    constructor: (@constTable, @symTable) ->

    visitProgram: (node) ->
        # TODO
