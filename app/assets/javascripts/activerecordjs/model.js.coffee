class Model
  @tableName = null
  @exec = ARJS.exec # convience method

  # instance

  constructor: (attrs) ->
    @_define(@_attrsInSchema(attrs))
    @_lastSaved = {}

  isSaved: ->
    @_dirtyAttributes().length == 0

  attrs: ->
    a = {}
    for k in @.constructor.keys
      a[k] = @[k]
    a

  _define: (attrs) ->
    for k, v of attrs
      @[k] = v

  # verifies the attributes are in schema
  _attrsInSchema: (attrs) ->
    vAttrs = {}
    for k, v of attrs
      if k in @.constructor.keys
        vAttrs[k] = v
    vAttrs

  # checks if there are any changes between last saved & current object.
  # returns keys for changed attributes
  _dirtyAttributes: ->
    changed = []
    for key in @.constructor.keys
      if @_lastSaved[key] != @[key]
        changed.push(key)
    changed

  # class methods

  @schema = (cb) ->
    ARJS.setupTable @tableName, cb

    # get table info & check which keys were created. store them in @keys
    if @isTableCreated
      result = @exec("PRAGMA table_info(#{@tableName})")[0]
      keys = []
      for v in result.values
        keys.push(v[1])
      @keys = keys
    else
      throw new Error('Unable to create the table')

  @isTableCreated = ->
    result = @exec("PRAGMA table_info(#{@tableName})")
    result.length > 0

window.ARJS.Model = Model