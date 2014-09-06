#= require application

describe 'arjs', ->

  describe 'setupTable', ->

    it 'should create the table', ->
      ARJS.setupTable 'users', (t) ->
        t.string('username')
        t.string('password')

      ARJS.db.exec('insert into users VALUES ("a", "b")')
      result = ARJS.db.exec('select * from users')

      expect(result[0].columns).toEqual(['username', 'password'])
      expect(result[0].values).toEqual([['a', 'b']])