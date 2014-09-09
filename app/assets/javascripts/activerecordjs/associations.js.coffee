class Relationship

  constructor: (@foreignName, @foreignKey, @foreignClassName, @myKey, @options) ->
    @foreignKey = @foreignKey.toLowerCase()
    @myKey = @myKey.toLowerCase()

  foreignClass: ->
    klass = ARJS._models[@foreignClassName]
    throw new Error("Relationship cannot be found: #{@foreignClassName}") if !klass?
    klass


class BelongsToRelationship extends Relationship

  called: (myModel, foreignModel) ->
    myModel[@myKey] ||= foreignModel[@foreignKey] if foreignModel?
    @foreignClass().where("#{@foreignKey} = ?", myModel[@myKey]).first()

class HasManyRelationship extends Relationship

  called: (myModel, foreignModels) ->
    =>
      if @options.through
        association = myModel.getAssociationByName(@options.through)
        throw new Error('unable to find association: ' + options.through) if !association?
        ids = association.called(myModel)().pluck(@foreignKey)
        @foreignClass().where("#{association.myKey} IN (?)", ids)
      else
        @foreignClass().where("#{@foreignKey} = ?", myModel[@myKey])

ARJS.Associations = {

  classMethods: {

    _setupAssociations: ->
      @_associations = {}

    belongsTo: (foreignName, options = {}) ->
      myKey = options.key || "#{foreignName}_id"
      foreignClass = options.className || ARJS.Inflection.classify(foreignName)
      foreignKey = options.foreignKey || 'id'
      @_associations[foreignName] = new BelongsToRelationship(foreignName, foreignKey, foreignClass, myKey, options)
    
    hasMany: (foreignName, options = {}) ->
      myKey = options.key || "id"
      foreignClassName = options.className || ARJS.Inflection.classify(foreignName)
      if options.through
        foreignKey = options.foreignKey || "#{ARJS.Inflection.singularize(foreignName)}_id"
      else
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