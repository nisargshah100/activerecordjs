class Model
  @tableName = null
  @exec = ARJS.exec # convience method

  # instance

  constructor: (attrs) ->
    @__id = ARJS.UUID() # is a unique id to find record from sql (internal use only) - auto added to schema
    @_define(@_attrsInSchema(attrs))
    @_lastSaved = null

  isSaved: ->
    @_dirtyAttributes().length == 0

  isNew: ->
    @_lastSaved == null

  attrs: ->
    a = {}
    for k in @.constructor.keys
      a[k] = @[k]
    a

  save: ->
    if @isNew()
      @_create()
    else
      @_update()

  # refresh the values & also sets the last saved hash since its straight from the database!
  _refresh: ->
    result = ARJS.exec(@_knex().where({ __id: @__id }).limit(1).toString())
    hash = ARJS.resultsToHash(result)[0]
    delete hash['__id']
    @_define(hash)
    @_lastSaved = hash

  _create: ->
    a = @attrs()
    a['__id'] = @__id
    ARJS.exec(@_knex().insert(a).toString())
    @_refresh()

  _update: ->
    da = @_dirtyAttributes()
    return if da.length == 0
    changedHash = {}
    changedHash[k] = @[k] for k in da
    q = @_knex().where('__id', '=', @__id).update(changedHash).toString()
    ARJS.exec(q)
    @_refresh()


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
    return @.constructor.keys if @isNew()

    changed = []
    for key in @.constructor.keys
      if @_lastSaved[key] != @[key]
        changed.push(key)
    changed

  _knex: ->
    ARJS.knex(@.constructor.tableName)

  # class methods

  @schema = (cb) ->
    ARJS.setupTable @tableName, (t) ->
      cb(t)
      t.string('__id').index()

    # get table info & check which keys were created. store them in @keys
    if @isTableCreated
      result = @exec("PRAGMA table_info(#{@tableName})")[0]
      keys = []
      for v in result.values
        keys.push(v[1]) if v[1] != '__id'
      @keys = keys
    else
      throw new Error('Unable to create the table')

  @isTableCreated = ->
    result = @exec("PRAGMA table_info(#{@tableName})")
    result.length > 0

window.ARJS.Model = Model