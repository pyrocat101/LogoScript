parser = require './parser'
tree = require './tree'
codeObject = require './codeObj'
codeGen = require './codeGen'
symTab = require './symTable'
logoVM = require './vm'
builtins = require './builtins'

@VERSION = '0.1.0'

registerBuiltins = (funcTable, builtins) ->
  for builtin in builtins
    funcTable.add builtin.name, builtin.argc

# add built-in functions
builtinFuncs = []
print = new codeObject.BuiltinFunction 'print', 1, console.log
builtinFuncs.push print
# math functions
builtins.getMathFuncs (name, func, argc) ->
  f = new codeObject.BuiltinFunction name, argc, func
  builtinFuncs.push f

@run = (src, options = {}) ->
  parseTree = parser.parse src
  tabSet = new symTab.SymTabSet()

  # Turtle
  turtleOpt =
    width: options.width
    height: options.height
    output: options.output
    antialias: options.antialias

  turtle = new builtins.Turtle turtleOpt
  # drawing functions
  turtle.getFuncs (name, func, argc) ->
    f = new codeObject.BuiltinFunction name, argc, func
    builtinFuncs.push f

  registerBuiltins tabSet.funcs, builtinFuncs

  parseTree.accept new tree.FirstPassVisitor tabSet

  # show parse tree
  console.log(require('util').inspect(parseTree, false, null)) if options.ast

  codeObj = new codeObject.CodeObject(tabSet.consts,
                                      tabSet.globals,
                                      tabSet.funcs,
                                      tabSet.locals)
  codeGenerator = codeGen.getGenerator codeObj
  parseTree.accept new tree.SecondPassVisitor codeGenerator

  # add builtin functions into code object
  codeObj.addBuiltinFuncs builtinFuncs

  # generate code
  parseTree.genCode()

  # view byte code
  codeObj.dump() if options.dump
  #console.log codeObj.functions
  #console.log codeObj.constNames
  #console.log codeObj.globalNames

  # kick it!
  vm = new logoVM.LogoVM codeObj
  vm.run()