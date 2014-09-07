ARJS.Hooks = {

  classMethods: {
    beforeSave: (name_or_cb) ->
      @hooks['beforeSave'].push(@_getHookCallback(name_or_cb))

    afterSave: (name_or_cb) ->
      @hooks['afterSave'].push(@_getHookCallback(name_or_cb))

    beforeCreate: (name_or_cb) ->
      @hooks['beforeCreate'].push(@_getHookCallback(name_or_cb))

    afterCreate: (name_or_cb) ->
      @hooks['afterCreate'].push(@_getHookCallback(name_or_cb))

    afterInitialize: (name_or_cb) ->
      @hooks['afterInitialize'].push(@_getHookCallback(name_or_cb))

    beforeUpdate: (name_or_cb) ->
      @hooks['beforeUpdate'].push(@_getHookCallback(name_or_cb))

    afterUpdate: (name_or_cb) ->
      @hooks['afterUpdate'].push(@_getHookCallback(name_or_cb))

    _getHookCallback: (name) ->
      if typeof(name) == 'string'
        cb = @[name]
        throw new Error("unable to find method (hook): #{name}, make sure the method is above hook otherwise js wont be able to find it") if !cb?
      else
        cb = name
      cb

    _setupHooks: ->
      @hooks = {
        'beforeSave': [],
        'afterSave': [],
        'beforeCreate': [],
        'afterCreate': [],
        'beforeUpdate': [],
        'afterUpdate': [],
        'afterInitialize': [],
        'beforeValidation': [],
        'afterValidation': [],
        'beforeDestroy': [],
        'afterDestroy': []
      }
  }

  instanceMethods: {

    _callAllHooks: (name, options={}) ->
        cb.call(@) for cb in @.constructor.hooks[name] if options.runHooks != false

  }
}