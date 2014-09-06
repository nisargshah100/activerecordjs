ARJS.db = new SQL.Database()
ARJS.knex = Knex(client: 'sqlite3')

ARJS.exec = (query) ->
  ARJS.db.exec(query)

ARJS.setupTable = (tableName, cb) ->
  q = ARJS.knex.schema.createTable tableName, (t) -> cb(t)
  ARJS.exec(q.toString())

ARJS.UUID = (length=64) ->
  id = ""
  id += Math.random().toString(36).substr(2) while id.length < length
  id.substr 0, length

ARJS.resultsToHash = (results) ->
  keys = results[0].columns
  valuesArray = results[0].values

  # keys come back as - ['a', 'b', 'c']
  # values are an array of array - 
  # [
  #   [1, 2, 3],
  #   [2, 3, 4]
  # ]
  # creates a hash object of arrays
  # [
  #    { a: 1, b: 2, c: 3},
  #    { a: 2, b: 3, c: 4}
  # ]

  records = []

  for values in valuesArray
    record = {}
    for x in [0...keys.length]
      record[keys[x]] = values[x]
    records.push(record)

  records

