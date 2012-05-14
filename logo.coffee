fs = require 'fs'
parser = require './parser'
tree = require './tree'
codeObject = require './codeObj'
codeGen = require './codeGen'
symTab = require './symTable'
logoVM = require './vm'
builtins = require './builtins'

registerBuiltins = (funcTable, builtins) ->
  for builtin in builtins
    funcTable.add builtin.name, builtin.argc

# add built-in functions
builtinFuncs = []
print = new codeObject.BuiltinFunction 'print', 1, console.log
builtinFuncs.push print
# math functions
builtins.getMathFuncs (name, func, argc) ->
  f = new codeObj.BuiltinFunction name, argc, func
  builtinFuncs.push f
# Turtle
turtle = new builtins.Turtle
# drawing functions
turtle.getFuncs (name, func, argc) ->
  f = new codeObj.BuiltinFunction name, argc, func
  builtinFuncs.push f

throw new Error "no input file" if process.argv.length < 3
fs.readFile process.argv[2], 'utf-8', (err, data) ->
  console.error err if err

  parseTree = parser.parse data
  tabSet = new symTab.SymTabSet()

  registerBuiltins tabSet.funcs, builtinFuncs

  pass1 = new tree.FirstPassVisitor tabSet
  parseTree.accept pass1

  console.log(require('util').inspect(parseTree, false, null))

  codeObj = new codeObject.CodeObject(tabSet.consts,
                                   tabSet.globals,
                                   tabSet.funcs,
                                   tabSet.locals)
  codeGenerator = codeGen.getGenerator codeObj
  pass2 = new tree.SecondPassVisitor codeGenerator
  parseTree.accept pass2

  # add builtin functions into code object
  codeObj.addBuiltinFuncs builtinFuncs

  # generate code
  parseTree.genCode()

  # view byte code
  codeObj.dump()
  #console.log codeObj.functions
  #console.log codeObj.constNames
  #console.log codeObj.globalNames

  # kick it!
  vm = new logoVM.LogoVM codeObj
  vm.run()
  # test: draw image
  turtle.drawImage 'output.png'
