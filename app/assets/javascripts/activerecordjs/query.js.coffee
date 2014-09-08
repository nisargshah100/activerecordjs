class QueryBuilder

  constructor: (@model) ->
    @knex = @model.knex()
    @

  where: (q, params) ->
    return @ if !q?
    q = ARJS.knex.raw(q, params) if typeof(q) == 'string'
    @knex = @knex.where(q)
    @

  first: ->
    hash = ARJS.resultsToHash(ARJS.exec(@knex.first().toString()))
    if hash.length == 1
      new @model(hash[0], _wrap: true)
    else
      null

  last: ->
    # this is higher performance than just calling all since it only wraps the last
    # object and not all objects
    results = ARJS.exec(@knex.toString())
    if results.length == 1
      vals = results[0].values
      if vals.length > 0
        result = ARJS.resultsToHash([{ columns: results[0].columns, values: [vals[vals.length-1]] }])
        return new @model(result[0], _wrap: true)

    null

  distinct: (attrs...) ->
    attrs = ['__id'] if attrs.length == 0
    @knex.distinct(attrs)
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

  all: ->
    results = []
    for hash in ARJS.resultsToHash(ARJS.exec(@knex.toString()))
      results.push(new @model(hash, _wrap: true))
    results

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

    where: (q, params) ->
      new QueryBuilder(@).where(q, params)

    all: ->
      new QueryBuilder(@).all()

    pluck: (attrs...) ->
      new QueryBuilder(@).pluck(attrs...)

    having: (q, op, val) ->
      new QueryBuilder(@).having(q, op, val)
  }

  instanceMethods: {

  }

}