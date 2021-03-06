describe 'Query', ->

  class User extends ARJS.Model
    @setup 'users_querys', timestamps: true
    @schema (t) ->
      t.string('email')
      t.string('password')
      t.string('name')
      t.string('token')

    @beforeCreate ->
      @token = '123'

  for x in [1..100]
    User.create(email: "a#{x}@a.com", password: 'abcdef', name: "user#{x}")
  
  it 'finds all users', ->
    users = User.all()
    expect(users.length).toBe(100)
    expect(users[0].email).toEqual('a1@a.com')
    expect(users[1].email).toEqual('a2@a.com')

  it 'first user', ->
    expect(User.first().email).toEqual('a1@a.com')
    expect(User.where('token = ?', '123').first().email).toEqual('a1@a.com')

  it 'last user', ->
    expect(User.last().email).toEqual('a100@a.com')
    expect(User.where('email LIKE ?', '%a%').last().email).toEqual('a100@a.com')

  it 'limits', ->
    expect(User.limit(10).all().length).toBe(10)

  it 'limits after offset', ->
    u = User.limit(10).offset(10).all()
    expect(u.length).toBe(10)
    expect(u[0].email).toEqual('a11@a.com')

  it 'plucks attributes', ->
    u = User.pluck('email', 'password')[0]
    expect(u[0]).toEqual('a1@a.com')
    expect(u[1]).toEqual('abcdef')
    expect(u.length).toBe(2)

  it 'returns distinct queries', ->
    expect(User.distinct('password').all().length).toBe(1)
    expect(User.where('password = ?', 'abcdef').distinct().all().length).toBe(100)
    expect(User.where('password = ?', 'abcdef').distinct('password').all().length).toBe(1)

  it 'orders the records', ->
    expect(User.orderBy('created_at asc').first().email).toEqual('a1@a.com')
    expect(User.orderBy('created_at desc').first().email).toEqual('a100@a.com')

  it 'groups the records', ->
    user = User.create(email: "a#{x}@a.com", password: 'boo', name: "user#{x}")
    expect(User.groupBy('password').all().length).toBe(2)
    user.destroy()

  it 'having in record', ->
    user = User.create(email: "a#{x}@a.com", password: 'boo', name: "user#{x}")
    u = User.groupBy('password').having('password', '=', 'boo').all()
    expect(u.length).toBe(1)
    expect(u[0].password).toEqual('boo')
    user.destroy()

  it 'count', ->
    expect(User.count()).toBe(100)
    expect(User.where('email = ?', 'a1@a.com').count()).toBe(1)

  describe 'transaction', ->
    Txn = null

    beforeEach ->
      class Txn extends ARJS.Model
        @setup 'txns'
        @schema (t) -> t.string('name')
        @validates 'name', presence: true

    afterEach ->
      ARJS.exec('drop table txns')

    it 'works', ->
      Txn.transaction ->
        Txn.createOrError(name: 'awesome')
        Txn.createOrError(name: 'boo')

      expect(Txn.count()).toBe(2)

      try
        Txn.transaction =>
          Txn.createOrError(name: 'awesome')
          expect(Txn.count()).toBe(3)
          Txn.createOrError()
      catch e
        expect(e.name).toEqual('RecordInvalid')

      expect(Txn.count()).toBe(2)

    it 'supports nested transactions', ->
      try
        Txn.transaction ->
          Txn.createOrError(name: 'great!')
          try
            Txn.transaction ->
              Txn.createOrError(name: 'foo')
              Txn.createOrError()
          catch e
            expect(e.name).toEqual('RecordInvalid')

      expect(Txn.count()).toBe(1)
      expect(Txn.first().name).toEqual('great!')

    it 'transaction throws error with messages', ->
      try
        Txn.transaction ->
          Txn.createOrError()
      catch e
        expect(e.errors).toEqual({ name: ['is required']})
        expect(e.model.__id).not.toBe(undefined)

    it 'where on null', ->
      User.create(name: 'boo')
      expect(User.count()).toBe(101)
      expect(User.where('email = ?', null).count()).toBe(1)
      expect(User.where('email = ?', undefined).count()).toBe(1)
      expect(User.where('email = ? AND password = ?', null, null).count()).toBe(1)
      expect(User.where('email = ?', null).where('password = ?', null).where('name = ?', 'boo').count()).toBe(1)
      expect(User.where('email = ?', null).where('password = ?', null).where('name = ?', 'boos').count()).toBe(0)
      # expect(User.where('email = ? AND password = ? AND name = ?', null, null, 'boo').count()).toBe(1)
      # expect(User.where('email = ? AND password = ? AND name = ?', null, null, 'boos').count()).toBe(0)
      expect(User.where({ email: null, password: null, name: 'boo' }).count()).toBe(1)
      expect(User.where({ email: null, password: null, name: 'boos' }).count()).toBe(0)

  it 'find', ->
    u = User.create(name: 'boo1')
    u2 = User.create(name: 'boo2')

    expect(User.find({ name: 'boo1' }).name).toEqual('boo1')
    expect(User.find({ name: 'crap' })).toBe(null)

    u.destroy()
    u2.destroy()

  it 'findOrError', ->
    u = User.create(name: 'boo1')
    u2 = User.create(name: 'boo2')
    expect(User.findOrError({ name: 'boo1' }).name).toEqual('boo1')
    expect(-> User.findOrError({ name: 'crap' })).toThrow(new ARJS.Errors.RecordNotFound({ name: 'crap' }))
    u.destroy()
    u2.destroy()

  it 'select', ->
    expect(User.first().password).toEqual('abcdef')
    expect(User.select('email').first().password).toBe(null)