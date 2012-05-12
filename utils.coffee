mixinKeywords = ['extended', 'included']

class @Mixins
  @extends: (obj) ->
    for key, value of obj when key not in mixinKeywords
      @[key] = value
    obj.extended?.apply this
    this

  @include: (obj) ->
    for key, value of obj when key not in mixinKeywords
      # Assign properties to the prototype
      @::[key] = value
    obj.included?.apply this
    this

  
