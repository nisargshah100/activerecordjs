class Relationship

  constructor: (@foreignName, @foreignKey, @foreignClassName, @myKey, @options) ->

  foreignClass: ->
    klass = ARJS._models[@foreignClassName]
    throw new Error("Relationship cannot be found: #{@foreignClassName}") if !klass?
    klass


class BelongsToRelationship extends Relationship

  called: (myModel, foreignModel) ->
    myModel[@myKey] ||= foreignModel[@foreignKey] if foreignModel?
    @foreignClass().where("#{@foreignKey} = ?", myModel[@myKey]).first()

  setup: (name, value, model) ->
    # model[name] = 


class HasManyRelationship extends Relationship

  called: (myModel, foreignModels) ->
    =>
      @foreignClass().where("#{@foreignKey} = ?", myModel[@myKey])

ARJS.Associations = {

  classMethods: {

    _setupAssociations: ->
      @_associations = {}
      # @_associationsByKey = {}

    belongsTo: (foreignName, options = {}) ->
      myKey = options.key || "#{foreignName}_id"
      foreignClass = options.className || ARJS.Inflection.classify(foreignName)
      foreignKey = options.foreignKey || 'id'
      @_associations[foreignName] = new BelongsToRelationship(foreignName, foreignKey, foreignClass, myKey, options)
    
    hasMany: (foreignName, options = {}) ->
      myKey = options.key || "id"
      foreignClassName = options.className || ARJS.Inflection.classify(foreignName)
      foreignKey = options.foreignKey || "#{ARJS.Inflection.singularize(@.name)}_id"
      @_associations[foreignName] = new HasManyRelationship(foreignName, foreignKey, foreignClassName, myKey, options)
  }

  instanceMethods: {

    # this is called for every object created. It does nothing unless
    # there is an association defined & an attr matched it. 
    _defineAssociations: (attrs = {}) ->
      return if ARJS.isObjectEmpty(@getAssociations())

      for name, association of @getAssociations()
        @[name] = association.called(@, attrs[name])

    getAssociations: ->
      @.constructor._associations

    getAssociationByName: (name) ->
      @.constructor._associations[name]

  }

}