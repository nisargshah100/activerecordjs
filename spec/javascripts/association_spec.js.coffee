describe 'Associations', ->
  User = null
  Book = null

  beforeEach ->
    ARJS.exec('drop table IF EXISTS users')
    class User extends ARJS.Model
      @setup 'users'
      @hasMany 'books', key: '__id'
      @schema (t) ->
        t.string('email')
        t.string('password')

    ARJS.exec('drop table IF EXISTS books')
    class Book extends ARJS.Model
      @setup 'books'
      @belongsTo 'user', foreignKey: '__id'
      @schema (t) ->
        t.string('name')
        t.integer('user_id')

  describe 'belongs to', ->

    it 'creates accessor for model with model passed in', ->
      user = User.create(email: 'a@a.com', password: 'foo bar')
      book = Book.create(name: 'Harry Potter', user: user)

      expect(Book._associations['user']).not.toBe(undefined)
      expect(book.user.email).toEqual('a@a.com')
      expect(book.user_id).toEqual(user.__id)

    it 'creates accessor for model with id passed in', ->
      user = User.create(email: 'a@a.com', password: 'foo bar')
      book = Book.create(name: 'Harry Potter', user_id: user.__id)
      book2 = Book.create(name: 'Second Book')

      expect(Book._associations['user']).not.toBe(undefined)
      expect(book.user.email).toEqual('a@a.com')
      expect(book.user_id).toEqual(user.__id)
      expect(book2.user).toBe(null)

    it 'retrieved model from db to have association setup', ->
      User.create(email: 'a@a.com', password: 'foo bar')
      Book.create(name: 'Harry Potter', user: User.first())

      expect(Book.last().user.email).toEqual(User.first().email)

    it 'update attributes', ->
      user = User.create(email: 'a@a.com', password: 'foo bar')
      book = Book.create(name: 'Harry Potter')
      book2 = Book.create(name: 'Harry Potter 2')

      expect(book2.updateAttributes(user: user)).toBe(true)
      expect(book2.user.email).toEqual(user.email)
      expect(book2.user_id).toEqual(user.__id)

      expect(book.updateAttributes(user_id: user.__id)).toBe(true)
      expect(book.user.email).toEqual(user.email)

      book3 = Book.create(name: 'Harry Potter 3')
      book3.user_id = user.__id
      book3.save()

      expect(book3.user.email).toEqual(user.email)
      expect(book3.user_id).toEqual(user.__id)

  describe 'has many', ->

    it 'creates accessor for models', ->
      user = User.create(email: 'a@a.com', password: 'foo bar')
      book = Book.create(name: 'Harry Potter', user: user)
      book2 = Book.create(name: 'Second book', user_id: user.__id)
      book3 = Book.create(name: 'Third book')

      user2 = User.create(email: 'b@b.com', password: 'me')
      book4 = Book.create(name: 'Forth book', user: user2)

      expect(user.books().count()).toBe(2)
      expect(user.books().orderBy('name').first().name).toEqual('Harry Potter')
      expect(user.books().orderBy('name').last().name).toEqual('Second book')

      expect(User.find({ email: 'b@b.com' }).books().count()).toBe(1)
      expect(User.find({ email: 'b@b.com' }).books().first().attrs()).toEqual(book4.attrs())

      book3.updateAttributes(user: user2)
      expect(User.find({ email: 'b@b.com' }).books().count()).toBe(2)
      expect(User.find({ email: 'b@b.com' }).books().orderBy('name DESC').first().attrs()).toEqual(book3.attrs())