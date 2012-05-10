parser = require './parser'
fs = require 'fs'

throw new Error("no input file") if process.argv.length < 3
fs.readFile process.argv[2], 'utf-8', (err, data) ->
  console.error(err) if err
  parseTree = parser.parse(data)

