class Model
  @tableName = null
  @exec = ARJS.exec # convience method
  @hooks = {
    'beforeSave': [],
    'afterSave': [],
    'afterInitialize': [],
    'afterCreate': [],
    'beforeCreate': [],
    'afterUpdate': [],
    'beforeUpdate': []
  }

  # instance

  constructor: (attrs) ->
    @__id = ARJS.UUID() # is a unique id to find record from sql (internal use only) - auto added to schema
    @_define(@_attrsInSchema(attrs))
    @_lastSaved = null
    @_callAllHooks('afterInitialize')

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
    @_callAllHooks('beforeSave')
    if @isNew()
      res = @_create()
    else
      res = @_update()
    @_callAllHooks('afterSave')
    res

  update_attributes: (attrs) ->
    @[k] = v for k, v of attrs
    @_update()


  # refresh the values & also sets the last saved hash since its straight from the database!
  _refresh: ->
    result = ARJS.exec(@_knex().where({ __id: @__id }).limit(1).toString())
    hash = ARJS.resultsToHash(result)[0]
    delete hash['__id']
    @_define(hash)
    @_lastSaved = hash

  _create: ->
    @_callAllHooks('afterCreate')
    a = @attrs()
    a['__id'] = @__id
    ARJS.exec(@_knex().insert(a).toString())
    @_refresh()
    @_callAllHooks('beforeCreate')
    true

  _update: ->
    @_callAllHooks('beforeUpdate')
    da = @_dirtyAttributes()
    return if da.length == 0
    changedHash = {}
    changedHash[k] = @[k] for k in da
    q = @_knex().where('__id', '=', @__id).update(changedHash).toString()
    ARJS.exec(q)
    @_refresh()
    @_callAllHooks('afterUpdate')
    true


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

  _callAllHooks: (name) ->
    cb.call(@) for cb in @.constructor.hooks[name]

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

  # create all the hook methods

  @beforeSave = (name) ->
    @hooks['beforeSave'].push(@_getHookCallback(name))

  @afterInitialize = (name) ->
    @hooks['afterInitialize'].push(@_getHookCallback(name))

  @beforeUpdate = (name) ->
    @hooks['beforeUpdate'].push(@_getHookCallback(name))

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

  @_getHookCallback: (name) ->
    if typeof(name) == 'string'
      cb = @[name]
      throw new Error("unable to find method (hook): #{name}, make sure the method is above hook otherwise js wont be able to find it") if !cb?
    else
      cb = name
    cb

window.ARJS.Model = Model