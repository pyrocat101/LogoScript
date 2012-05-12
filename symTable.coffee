# export symbol flags
SYM_NONE = 0
SYM_LOCAL = 1
SYM_GLOBAL = 2
SYM_FUNC = 3
@SYM_NONE = SYM_NONE
@SYM_LOCAL = SYM_LOCAL
@SYM_GLOBAL = SYM_GLOBAL
@SYM_FUNC = SYM_FUNC

# private function to count keys in an associative array
_dictCount = (obj) -> Object.keys(obj).length

class ConstTable
  constructor: (name) ->
    @name = name
    @_set = {}

  contains: (obj) -> obj of @_set

  #put: (obj) -> @_set[obj] = _dictCount(@_set) if obj not in @_set
  put: (obj) -> 
    if obj not of @_set
      @_set[obj] = _dictCount @_set
    else
      @_set[obj]

  count: -> _dictCount(@_set)

  get: (obj) -> @_set[obj]

  forEach: (cb, ctx = this) ->
    cb.call(ctx, k, nr) for own k, nr of @_set

class SymTabEntry
  constructor: (@flag, @number) ->

class SymTable
  constructor: ->
    @_dict = {}

  _add: (name, flag) ->
    ste = new SymTabEntry(flag, @count())
    @_dict[name] = ste

  count: -> _dictCount @_dict

  contains: (name) -> name of @_dict

  get: (name) -> @_dict[name]

  forEach: (cb, ctx = this) ->
    cb.call(ctx, k, ste) for own k, ste of @_dict

class GlobalVars extends SymTable
  add: (name) -> @_add name, SYM_GLOBAL

class LocalVars extends SymTable
  add: (name) -> @_add name, SYM_LOCAL

class FuncTable extends SymTable
  add: (name) -> @_add name, SYM_FUNC

class SymTabSet
  constructor: ->
    @globals = new GlobalVars()
    @locals = {}
    @consts = new ConstTable()
    @funcs = new FuncTable()
    @currentTab = @globals

  isGlobal: (name) -> @globals.contains name

  isFunc: (name) -> @funcs.contains name

  enter: (table) -> @currentTab = table

  enterGlobal: -> @currentTab = @globals
  
  # create a local symbol scope and set it as current scope
  addLocal: (name) ->
    localTab = new @LocalVars()
    @locals[name] = localTab
    @enter localTab


# exports
@ConstTable = ConstTable
@GlobalVars = GlobalVars
@LocalVars = LocalVars
@FuncTable = FuncTable
@SymTabSet = SymTabSet
@SymTabEntry = SymTabEntry
