class QueryBuilder

  constructor: (@model) ->
    @knex = @model.knex()
    @

  where: (q, params...) ->
    return @ if !q?
    q = ARJS.knex.raw(q, params) if typeof(q) == 'string'
    @knex = @knex.where(q, params)
    @

  first: ->
    hash = ARJS.resultsToHash(ARJS.exec(@_queryParser(@knex.first().toString())))
    if hash.length == 1
      new @model(hash[0])
    else
      null

  last: ->
    # this is higher performance than just calling all since it only wraps the last
    # object and not all objects
    results = ARJS.exec(@_queryParser(@knex.toString()))
    if results.length == 1
      vals = results[0].values
      if vals.length > 0
        result = ARJS.resultsToHash([{ columns: results[0].columns, values: [vals[vals.length-1]] }])
        return new @model(result[0])

    null

  distinct: (attrs...) ->
    attrs = ['__id'] if attrs.length == 0
    @knex.distinct(attrs)
    @

  select: (attrs...) ->
    @knex.select(attrs)
    @

  limit: (count) ->
    @knex.limit(count)
    @

  offset: (count) ->
    @knex.offset(count)
    @

  pluck: (attrs...) ->
    models = @all()
    results = []
    
    if attrs.length == 1
      for model in models
        for attr in attrs
          results.push model[attr]
    else
      for model in models
        val = []
        for attr in attrs
          val.push model[attr]
        results.push(val)

    results

  orderBy: (x, y) ->
    if typeof(x) == 'string' && !y?
      vals = x.split(' ')
      x = vals[0]
      y = vals[1]

    @knex.orderBy(x, y)
    @

  groupBy: (q) ->
    @knex.groupByRaw(q)
    @

  having: (q, op, val) ->
    @knex.having(q, op, val)
    @

  count: ->
    ARJS.exec(@_queryParser(@knex.count().toString()))[0].values[0][0]

  all: ->
    results = []
    for hash in ARJS.resultsToHash(ARJS.exec(@_queryParser(@knex.toString())))
      results.push(new @model(hash))
    results

  toString: ->
    @_queryParser(@knex.toString())

  _queryParser: (query) ->
    query.replace(/\= NULL/g, 'is NULL')

ARJS.Query = {

  classMethods: {

    orderBy: (x, y) ->
      new QueryBuilder(@).orderBy(x, y)

    groupBy: (q) ->
      new QueryBuilder(@).groupBy(q)

    distinct: (attrs...) ->
      new QueryBuilder(@).distinct(attrs...)

    limit: (count) ->
      new QueryBuilder(@).limit(count)

    offset: (count) ->
      new QueryBuilder(@).offset(count)

    last: ->
      new QueryBuilder(@).last()

    first: ->
      new QueryBuilder(@).first()

    where: (q, params...) ->
      new QueryBuilder(@).where(q, params...)

    all: ->
      new QueryBuilder(@).all()

    pluck: (attrs...) ->
      new QueryBuilder(@).pluck(attrs...)

    having: (q, op, val) ->
      new QueryBuilder(@).having(q, op, val)

    count: ->
      new QueryBuilder(@).count()

    find: (attrs) ->
      return null if !attrs?
      new QueryBuilder(@).where(attrs).first()

    findOrError: (attrs) ->
      val = @find(attrs)
      throw new ARJS.Errors.RecordNotFound(attrs) if not val || not attrs
      val

    select: (attrs...) ->
      new QueryBuilder(@).select(attrs)

    transaction: (fn) ->
      uniqueId = "a#{ARJS.UUID()}" # savepoint has to start with a letter
      try
        ARJS.exec("SAVEPOINT #{uniqueId}")
        fn()
        ARJS.exec("RELEASE SAVEPOINT #{uniqueId}")
        return true
      catch e
        ARJS.exec("ROLLBACK TO #{uniqueId}")
        throw e
  }

  instanceMethods: {

  }

}