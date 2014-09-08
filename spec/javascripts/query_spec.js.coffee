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