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

  describe 'has many through', ->
    Person = null
    Account = null
    PersonAccount = null

    beforeEach ->
      ARJS.exec('drop table IF EXISTS persons')
      class Person extends ARJS.Model
        @setup 'persons'
        @hasMany 'person_accounts', key: '__id'
        @hasMany 'accounts', through: 'person_accounts'
        @schema (t) ->
          t.string('email')

      ARJS.exec('drop table IF EXISTS person_accounts')
      class PersonAccount extends ARJS.Model
        @setup 'person_accounts'
        @belongsTo 'person', foreignKey: '__id'
        @belongsTo 'account', foreignKey: '__id'
        @schema (t) ->
          t.string('person_id')
          t.string('account_id')

      ARJS.exec('drop table IF EXISTS accounts')
      class Account extends ARJS.Model
        @setup 'accounts'
        @hasMany 'person_accounts', key: '__id'
        @hasMany 'persons', through: 'person_accounts'
        @schema (t) ->
          t.string('name')

    # select account_id from person_accounts where person_accounts.person_id == __id
    # select * from accounts where __id IN (accountIds)

    it 'creates accessor for models', ->
      p1 = Person.create(email: 'a@a.com')
      a1 = Account.create(name: 'First Account')
      Account.create(name: 'Second Account')
      Person.create(email: 'b@b.com')
      PersonAccount.create(person: p1, account: a1)

      expect(p1.person_accounts().first().account_id).toEqual(a1.__id)
      expect(a1.person_accounts().first().person_id).toEqual(p1.__id)
      expect(PersonAccount.first().person.email).toEqual('a@a.com')
      expect(PersonAccount.first().account.name).toEqual('First Account')

      expect(p1.accounts().count()).toBe(1)
      expect(p1.accounts().first().name).toEqual('First Account')
      expect(a1.persons().count()).toBe(1)
      expect(a1.persons().first().email).toEqual('a@a.com')

    it 'works with multiple models', ->
      p1 = Person.create(email: 'a@a.com')
      p2 = Person.create(email: 'b@a.com')
      p3 = Person.create(email: 'c@a.com')
      a1 = Account.create(name: 'First Account')
      a2 = Account.create(name: 'Second Account')
      a3 = Account.create(name: 'Third Account')

      PersonAccount.create(person: p1, account: a1)
      PersonAccount.create(person: p2, account: a1)
      PersonAccount.create(person: p3, account: a1)

      console.log a1.persons().all()

      # expect(p1.accounts().count()).toBe(1)
      # expect(p2.accounts().count()).toBe(1)
      # expect(p3.accounts().count()).toBe(1)
      # expect(a1.persons().count()).toBe(3)
      # expect(a2.persons().count()).toBe(0)
      expect(a3.persons().count()).toBe(0)