ARJS.db = new SQL.Database()
ARJS.knex = Knex(client: 'sqlite3')

ARJS.exec = (query) ->
  ARJS.db.exec(query)

ARJS.setupTable = (tableName, cb) ->
  q = ARJS.knex.schema.createTable tableName, (t) -> cb(t)
  ARJS.exec(q.toString())