class Model extends ARJS.Module
  @tableName = null
  @exec = ARJS.exec # convience method
  @extend(ARJS.Hooks.classMethods)
  @include(ARJS.Hooks.instanceMethods)
  @extend(ARJS.Validation.classMethods)
  @include(ARJS.Validation.instanceMethods)
  @extend(ARJS.Query.classMethods)
  @include(ARJS.Query.instanceMethods)
  @extend(ARJS.Associations.classMethods)
  @include(ARJS.Associations.instanceMethods)

  # instance

  constructor: (attrs) ->
    if attrs && attrs.__id
      @__id = attrs.__id
      @_lastSaved = @_attrsInSchema(attrs)
    else
      @__id = ARJS.UUID() # is a unique id to find record from sql (internal use only) - auto added to schema
      @_lastSaved = null
    
    @_define(attrs)
    @_callAllHooks('afterInitialize')
    @

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

  saveOrError: (options = {}) ->
    res = @save(options)
    throw new ARJS.Errors.RecordInvalid(@errors(), @) if res != true

  updateAttributes: (attrs, options = {}) ->
    @_define(attrs)
    @_update(options)

  updateAttributesOrError: (attrs, options = {}) ->
    res = @updateAttributes(attrs, options)
    throw new ARJS.Errors.RecordInvalid(@errors(), @) if res != true

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

  destroyOrError: (options = {}) ->
    if @destroy(options) == false
      throw new ARJS.Errors.RecordInvalid(@errors(), @)
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
    @_setupValidation()
    @_callAllHooks('beforeValidation', options)
    @_validate('create')
    @_callAllHooks('afterValidation', options)

    return false if @hasErrors()

    @_callAllHooks('beforeSave', options)
    @_callAllHooks('beforeCreate', options)
    
    a = @attrs()
    a['__id'] = @__id
    ARJS.exec(@_knex().insert(a).toString())
    @_refresh()
    @_callAllHooks('afterCreate', options)
    @_callAllHooks('afterSave', options)
    true

  _update: (options) ->
    da = @_dirtyAttributes()
    # lets do some validation!
    @_setupValidation()
    @_callAllHooks('beforeValidation', options)
    @_validate('update')
    @_callAllHooks('afterValidation', options)

    return false if @hasErrors()

    @_callAllHooks('beforeSave', options)
    @_callAllHooks('beforeUpdate', options)

    if not @isSaved()
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
    for x in @.constructor.keys
      @[x] ||= null

    @_defineAssociations(attrs)

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

  @knex = ->
    ARJS.knex(@tableName)

  @setup = (tableName, options = {}) ->
    @tableName = tableName
    @_timestamps = options.timestamps
    @_setupHooks()
    @_setupValidations()
    @_setupTimestamps() if options.timestamps
    @_setupAssociations()
    ARJS._models[@.name] = @

  @schema = (cb) ->
    ARJS.setupTable @tableName, (t) =>
      cb(t)
      t.string('__id').index()
      t.timestamps() if @_timestamps

    # get table info & check which keys were created. store them in @keys
    if @isTableCreated
      result = @exec("PRAGMA table_info(#{@tableName})")[0]
      keys = []
      for v in result.values
        keys.push(v[1]) if v[1] != '__id'
      @keys = keys
    else
      throw new Error('Unable to create the table')

  @create = (args, options={}) ->
    user = new @(args)
    user.save(options)
    user

  @createOrError = (args, options={}) ->
    m = @create(args, options)
    throw new ARJS.Errors.RecordInvalid(m.errors(), m) if m.isNew()
    m

  @deleteAll = ->
    ARJS.exec(@knex().del().toString())
    true

  @destroyAll = ->
    try
      @.transaction =>
        for model in @.all()
          result = model.destroy()
          throw new Error('error') if result != true
      return true
    catch e
      return false

  @destroyAllOrError = ->
    @.transaction =>
      for model in @.all()
        result = model.destroyOrError()

  @isTableCreated = ->
    result = @exec("PRAGMA table_info(#{@tableName})")
    result.length > 0

  @_setupTimestamps = ->
    @afterCreate ->
      t = new Date()
      @updateAttributes(created_at: t, { runHooks: false })
      @updateAttributes(updated_at: t, { runHooks: false })

    @afterUpdate ->
      @updateAttributes(updated_at: new Date(), { runHooks: false })

window.ARJS.Model = Model