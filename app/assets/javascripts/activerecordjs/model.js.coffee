class Model extends ARJS.Module
  @tableName = null
  @exec = ARJS.exec # convience method
  @extend(ARJS.Hooks.classMethods)
  @include(ARJS.Hooks.instanceMethods)
  @extend(ARJS.Validation.classMethods)
  @include(ARJS.Validation.instanceMethods)

  # instance

  constructor: (attrs) ->
    @__id = ARJS.UUID() # is a unique id to find record from sql (internal use only) - auto added to schema
    @_define(attrs)
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

  save: (options = {}) ->
    if @isNew()
      res = @_create(options)
    else
      res = @_update(options)
    res

  update_attributes: (attrs, options = {}) ->
    @_define(attrs)
    @_update(options)

  reload: ->
    @_refresh()

  destroy: (options = {}) ->
    @_callAllHooks('beforeValidation', options)
    @_validate('destroy')
    @_callAllHooks('afterValidation', options)
    @_callAllHooks('beforeDestroy', options)
    return false if @hasErrors()

    ARJS.exec(@_knex().where({ __id: @__id }).del().toString())
    @_callAllHooks('afterDestroy', options)
    true

  # refresh the values & also sets the last saved hash since its straight from the database!
  _refresh: ->
    result = ARJS.exec(@_knex().where({ __id: @__id }).limit(1).toString())
    if result.length == 1
      hash = ARJS.resultsToHash(result)[0]
      delete hash['__id']
      @_define(hash)
      @_lastSaved = hash
      true
    else
      false

  _create: (options) ->
    # lets do some validation!
    @_callAllHooks('beforeValidation', options)
    @_validate('create')
    @_callAllHooks('afterValidation', options)

    @_callAllHooks('beforeSave', options)
    @_callAllHooks('beforeCreate', options)
    
    return false if @hasErrors()
    
    a = @attrs()
    a['__id'] = @__id
    ARJS.exec(@_knex().insert(a).toString())
    @_refresh()
    @_callAllHooks('afterCreate', options)
    @_callAllHooks('afterSave', options)
    true

  _update: (options) ->
    da = @_dirtyAttributes()
    return if da.length == 0

    # lets do some validation!
    @_callAllHooks('beforeValidation', options)
    @_validate('update')
    @_callAllHooks('afterValidation', options)

    @_callAllHooks('beforeSave', options)
    @_callAllHooks('beforeUpdate', options)
    
    return false if @hasErrors()

    changedHash = {}
    changedHash[k] = @[k] for k in da
    q = @_knex().where('__id', '=', @__id).update(changedHash).toString()
    ARJS.exec(q)
    @_refresh()
    @_callAllHooks('afterUpdate', options)
    @_callAllHooks('afterSave', options)
    true


  _define: (attrs) ->
    x = @_attrsInSchema(attrs)
    @[k] = v for k, v of x

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

  @setup = (tableName) ->
    @tableName = tableName
    @_setupHooks()
    @_setupValidations()

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