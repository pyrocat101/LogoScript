fs = require 'fs'
parser = require './parser'
tree = require './tree'
codeObj = require './codeObj'
codeGen = require './codeGen'
symTab = require './symTable'

throw new Error "no input file" if process.argv.length < 3
fs.readFile process.argv[2], 'utf-8', (err, data) ->
  console.error err if err

  parseTree = parser.parse data
  tabSet = new symTab.SymTabSet()

  pass1 = new tree.FirstPassVisitor tabSet
  parseTree.accept pass1

  console.log(require('util').inspect(parseTree, false, null))

  codeObj = new codeObj.CodeObject(tabSet.consts,
                                   tabSet.globals,
                                   tabSet.funcs,
                                   tabSet.locals)
  codeGenerator = codeGen.getGenerator codeObj
  pass2 = new tree.SecondPassVisitor(codeGenerator)
  parseTree.accept pass2

  # generate code
  parseTree.genCode()

  # view byte code
  codeObj.dump()