# export symbol flags
@SYM_LOCAL = 1
@SYM_NONLOCAL = 2
@SYM_FUNC = 3

# private function to count keys in an associative array
_dictCount = (obj) -> Object.keys(obj).length()

class @SymTableEntry
  constructor: (name) ->
    @name = name
    @_dict = {}
    @children = []
    @parent = @root = null

  addChild: (ste) -> @children.push(ste)
    
  isLocal: (name) -> @_dict[name] is SYM_LOCAL
    
  isFunc: (name) -> @_dict[name] is SYM_FUNC

  putSymbol: (name, flags) -> @_dict[name] = flags

  delSymbol: (name) -> delete @_dict[name]

  symbolCount: -> _dictCount(@_dict)

  childrenCount: -> @children.length()

  containsSymbol: (name) -> name of @_dict

  getChild: (nth) -> @children[nth]

  getSymbol: (name) -> @_dict[name]

  forEach: (cb, ctx) -> 
    ctx = this unless ctx?
    cb.call(ctx, k, nr, flags) for own k, [nr, flags] of @_dict
        
class @ConstTable
  constructor: (name) ->
    @name = name
    @_set = {}

  contains: (obj) -> obj of @_set

  putConst: (obj) -> @_set[obj] = _dictCount(@_set)

  constCount: -> _dictCount(@_set)

  getNumber: (obj) -> @_set[obj]

