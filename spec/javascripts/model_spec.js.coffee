#= require application

Foo = null

describe 'Model', ->

  beforeEach ->
    class Foo extends ARJS.Model
      @setup 'foos'
      @schema (t) ->
        t.integer('a')
        t.integer('b')

  afterEach ->
    ARJS.exec('drop table foos')

  it 'creates a table', ->
    expect(Foo.isTableCreated()).toBe(true)

  it 'can create multiple models', ->
    class A extends ARJS.Model
      @setup 'ast'
      @schema (t) -> t.string('name')
      @beforeSave -> console.log('ok1')

    class B extends ARJS.Model
      @setup 'bst'
      @schema (t) -> t.string('email')
      @beforeSave -> console.log('ok2')

    expect(A.tableName).toEqual('ast')
    expect(B.tableName).toEqual('bst')
    expect(A.hooks['beforeSave'].length).toBe(1)
    expect(B.hooks['beforeSave'].length).toBe(1)

  it 'any attribute not passed in is null and not undefined', ->
    f = new Foo(a: 1)
    expect(f.b).toBe(null)

  it 'creates an object and sets attributes', ->
    foo = new Foo(a: 1, b: 2)
    expect(foo.a).toBe(1)
    expect(foo.b).toBe(2)

  it 'rejects keys that are not in schema', ->
    foo = new Foo(a: 1, b: 2, c: 33)
    expect(foo.a).toBe(1)
    expect(foo.c).toBe(undefined)
    expect(foo.attrs()).toEqual({a: 1, b: 2})

  describe 'dirty attributes', ->
    
    it 'returns all attributes for new model', ->
      foo = new Foo(a:1, b:2)
      expect(foo._dirtyAttributes()).toEqual(['a', 'b'])

    it 'assume saved', ->
      foo = new Foo(a:1, b:2)
      foo._lastSaved = foo.attrs()
      expect(foo._dirtyAttributes()).toEqual([])
      expect(foo.isSaved()).toEqual(true)

    it 'assume one changed', ->
      foo = new Foo(a: 1, b: 2)
      foo._lastSaved = foo.attrs()
      foo.b = 3
      expect(foo._dirtyAttributes()).toEqual(['b'])

  it 'create returns object', ->
    foo = Foo.create(a: 1)
    expect(foo.a).toBe(1)

  describe 'save (new object)', ->

    it 'saves the model', ->
      foo = new Foo(a:1, b:2)
      foo.save()
      foo.save() # doesn't do anything second time! no dirty attributes
      foo.c = 3  # random attributes dont get saved
      foo.save()
      delete foo.c
      delete foo.a
      foo._refresh() # reload the attributes from sql - only a loaded, c not loaded
      expect(foo.isSaved()).toBe(true)
      expect(foo.c).toBe(undefined)
      expect(foo.a).toBe(1)

    it 'fails to save on error', ->
      Foo.validates 'a', presence: true
      foo = new Foo()
      expect(foo.save()).toBe(false)
      expect(-> foo.saveOrError()).toThrow(new ARJS.Errors.RecordInvalid({a: ['is required']}))

      try
        foo.saveOrError()
      catch e
        expect(e.model).toBe(foo)

  it 'destroy a object', ->
    foo = new Foo(a: 1, b: 2)
    expect(foo.destroy()).toBe(true)
    expect(foo.reload()).toBe(false)

  it 'destroy or error fails', ->
    Foo.validates 'a', presence: true, on: 'destroy'
    foo = Foo.createOrError()
    expect(-> foo.destroyOrError()).toThrow(new ARJS.Errors.RecordInvalid({a: ['is required']}))

    try
      foo.destroyOrError()
    catch e
      expect(e.model).toBe(foo)

  describe 'updates a object', ->

    it 'updates the model', ->
      foo = new Foo(a:1, b:2)
      foo.save()
      expect(foo.a).toBe(1)
      foo.a = 2
      foo.save()
      foo._refresh()
      expect(foo.a).toBe(2)

    it 'with update attributes', ->
      foo = new Foo(a: 1)
      foo.save()
      foo.updateAttributes(a: 2, b: 3)
      foo._refresh()
      expect(foo.a).toBe(2)
      expect(foo.b).toBe(3)

    it 'with update attributes fails error', ->
      Foo.validates 'a', presence: true

      foo = new Foo(a: 1)
      foo.save()
      expect(-> foo.updateAttributesOrError(a: null)).toThrow(new ARJS.Errors.RecordInvalid(a: ['is required']))
      
      try
        foo.updateAttributesOrError(a: null)
      catch e
        expect(e.model).toBe(foo)
      

  describe 'hooks', ->
    Boo = null
    str = ''

    beforeEach ->
      ARJS.exec('drop table IF EXISTS boos')
      class Boo extends ARJS.Model
        @setup 'boos'
        @schema (t) -> 
          t.string('name')
          t.string('token')

    describe 'before save', ->

      beforeEach ->
        Boo.bs = -> str += @name
        Boo.beforeSave 'bs'
        str = ''

      it 'assigns the hook properly', ->
        new Boo(name: 'apples').save()
        new Boo(name: 'second').save()
        expect(str).toEqual('applessecond')

      it 'gets called on update', ->
        b = new Boo(name: 'Great')
        b.save()
        b.name = 'Awesome'
        b.save()
        expect(str).toEqual('GreatAwesome')

    describe 'after save', ->

      beforeEach ->
        Boo.afterSave (options) ->
          @updateAttributes({ token: ARJS.UUID() }, runHooks: false)
          options.callback()

      it 'updates the token in after save hook', ->
        x = 0
        boo = new Boo(name: 'Cool')
        expect(boo.token).toEqual(null)
        boo.save(callback: -> x += 1)
        expect(boo.token).not.toEqual(null)
        expect(x).toBe(1)

    it 'before create', ->
      x = 0
      Boo.beforeCreate -> x += 1
      b = new Boo(name: 'apples')
      expect(x).toBe(0)
      b.save()
      expect(x).toBe(1)

    it 'after create', ->
      x = 0
      Boo.afterCreate -> x += 1
      b = new Boo(name: 'apples')
      expect(x).toBe(0)
      b.save()
      expect(x).toBe(1)
      b.a = 2
      b.save()
      expect(x).toBe(1)

    it 'after initialize gets called', ->
      x = 0
      Boo.afterInitialize -> x += 1
      new Boo(name: 'apples')
      expect(x).toBe(1)

    it 'before update gets called', ->
      x = 0
      Boo.beforeUpdate -> x += 1
      f = new Boo(name: 'apples')
      f.save()
      expect(x).toBe(0)
      f.name = 'apples3'
      f.save()
      expect(x).toBe(1)
      f.updateAttributes(name: 'apple2')
      expect(x).toBe(2)

    it 'after update gets called', ->
      x = 0
      Boo.afterUpdate -> x += 1
      f = new Boo(name: 'apples')
      f.save()
      expect(x).toBe(0)
      f.updateAttributes(name: 'apples2')
      expect(x).toBe(1)

  describe 'validations', ->
    Voo = null

    beforeEach ->
      class Voo extends ARJS.Model
        @setup 'voos'
        @schema (t) ->
          t.string 'name'
          t.string 'email'

    afterEach ->
      ARJS.exec('drop table voos')

    it 'accepts validates property & sets up the rules', ->
      Voo.validates 'email', 'presence': { msg: 'boo yeah' }
      expect(Voo._validationRules.email.length).toBe(1)
      expect(Voo._validationRules.email[0].validator.message()).toEqual('boo yeah')
      expect(Voo._validationRules.email[0].on).toEqual(['create', 'update'])

    it 'sets validation on method', ->
      Voo.validates 'email', presence: { msg: 'lol' }, on: 'update'
      expect(Voo._validationRules.email[0].on).toEqual(['update'])

      Voo.validates 'name', presence: { msg: 'lol' }, on: ['update', 'delete']
      expect(Voo._validationRules.name[0].on).toEqual(['update', 'delete'])

    it 'errors if invalid rule is specified', ->
      expect(-> Voo.validates('email', 'abcdef': true)).toThrow(new Error('unknown validator: abcdef'))

    it 'multiple classes with different validations', ->
      class VooTwo extends ARJS.Model
        @setup 'voostwo'
        @schema (t) ->
          t.string 'name'

        @validates 'name', presence: true

      Voo.validates 'email', presence: true
      
      expect(VooTwo._validationRules.email).toBe(undefined)
      expect(VooTwo._validationRules.name.length).toBe(1)
      expect(Voo._validationRules.email.length).toBe(1)
      expect(Voo._validationRules.name).toBe(undefined)
      ARJS.exec('drop table voostwo')

    it 'runs validation on model', ->
      Voo.validates 'email', presence: { msg: 'foo bar' }
      Voo.validates 'name', email: true # format must be email if specified. 

      v = new Voo(email: '')
      v._validate('create')
      expect(v.errorKeys()).toEqual(['email'])
      expect(v.errors()['email'].length).toBe(1)
      expect(v.errors()['email'][0]).toEqual('foo bar')

    it 'runs multiple validations', ->
      Voo.validates 'email', presence: true
      Voo.validates 'name', email: { msg: 'lala' }, presence: true
      v = new Voo()
      expect(v.hasErrors()).toBe(false)
      v._validate('create')
      expect(v.errorKeys()).toEqual(['name', 'email'])
      expect(v.errors()['email'][0]).toEqual('is required')
      expect(v.errors()['name'][0]).toEqual('is required')

      v.name = 'blah'
      v._validate('create')
      expect(v.errors()['name'].length).toBe(1)
      expect(v.errors()['name'][0]).toEqual('lala')
      expect(v.hasErrors()).toBe(true)

    it 'runs validation on save', ->
      Voo.validates 'email', presence: true, email: true
      v = new Voo()
      expect(v.save()).toBe(false)
      expect(v.errors()['email'][0]).toEqual('is required')
      v.updateAttributes(email: 'hi')
      expect(v.save()).toBe(false)
      expect(v.errors()['email'][0]).toEqual('must be an email address')
      expect(v.email).toEqual('hi')
      expect(v.reload()).toBe(false)
      expect(v.email).toEqual('hi')


    it 'runs validation on update only', ->
      Voo.validates 'email', presence: true, email: true, on: 'update'
      v = new Voo(email: 'boo')
      expect(v.save()).toBe(true)
      v.email = 'cool'
      expect(v.save()).toBe(false)
      expect(v.email).toEqual('cool')
      expect(v.reload()).toBe(true)
      expect(v.email).toEqual('boo')

    it 'runs validation on destroy', ->
      Voo.validates 'email', presence: true, on: 'destroy'
      v = new Voo()
      v.save()
      expect(v.destroy()).toBe(false)
      expect(v.reload()).toBe(true)
      v.email = 'a'
      v.save()
      expect(v.destroy()).toBe(true)

    it 'can add error on before create', ->
      Voo.beforeCreate ->
        @addError('email', 'something broke!')

      v = new Voo(email: 'lol')
      expect(v.save()).toBe(false)
      expect(v.errors().email[0]).toEqual('something broke!')

    it 'can add error on before update', ->
      Voo.beforeUpdate ->
        @addError('email', 'boo')

      v = new Voo(email: 'good')
      v.save()
      expect(v.updateAttributes(email: 'second')).toBe(false)
      expect(v.errors().email[0]).toEqual('boo')

  describe 'destroy all objects', ->
    beforeEach ->
      Foo.create(a: 1, b: 2)
      Foo.create(a: 2, c: 3)
      Foo.create(a: 3, b: 2)

    describe 'destroyAll', ->
      it 'suceeds and removes all', ->
        expect(Foo.destroyAll()).toBe(true)
        expect(Foo.count()).toBe(0)

      it 'fails and doesnt remove any', ->
        Foo.validates 'a', numericality: { greater_than: 2 }, on: 'destroy'
        expect(Foo.destroyAll()).toBe(false)
        expect(Foo.count()).toBe(3)

    describe 'destroyAllOrError', ->
      it 'suceeds and removes all', ->
        Foo.destroyAllOrError()
        expect(Foo.count()).toBe(0)

      it 'fails and doesnt remove any', ->
        Foo.validates 'a', numericality: { greater_than: 2, msg: 'foo' }, on: 'destroy'
        try
          Foo.destroyAllOrError()
        catch e
          expect(e.name).toEqual('RecordInvalid')
          expect(e.errors).toEqual({ a: ['foo']})
        expect(Foo.count()).toBe(3)

  it 'deletes all objects', ->
    class Apple extends ARJS.Model
      @setup 'apples'
      @schema (t) -> t.string('name')

    class Bat extends ARJS.Model
      @setup 'bats'
      @schema (t) -> t.string('email')

    Apple.create(name: 'one')
    Apple.create(name: 'two')
    Apple.create(name: 'three')

    Bat.create(email: '1')
    Bat.create(email: '2')
    Bat.create(email: '3')

    Apple.validates 'name', email: true, on: 'destroy'
    Apple.deleteAll()

    expect(Apple.count()).toBe(0)
    expect(Bat.count()).toBe(3)

  it 'error fails, then save and remove errors', ->
    Foo.validates 'a', presence: true
    f = new Foo(b: 2)
    expect(f.save()).toBe(false)
    expect(f.hasErrors()).toBe(true)
    f.a = 1
    expect(f.save()).toBe(true)
    expect(f.hasErrors()).toBe(false)
    expect(f.errors()).toEqual({})

  it 'find object, save it and refetch the changes', ->
    Foo.create(a: 1, b: 2)
    foo = Foo.where('a = ?', 1).where('b = ?', 2).first()
    foo.a = 3
    foo.save()
    expect(Foo.count()).toBe(1)
    expect(Foo.first().attrs()).toEqual({ a: 3, b: 2 })

    Foo.create(a: 100)
    f = Foo.where({ a: 100 }).first()
    expect(f.a).toBe(100)
    expect(f.b).toBe(null)

  describe 'unique attribute', ->
    it 'on single attribute', ->
      Foo.validates 'a', uniqueness: true
      expect(Foo.create(a: -1).hasErrors()).toBe(false)
      expect(Foo.create(a: -1).hasErrors()).toBe(true)

    it 'with scope', ->
      Foo.validates 'a', uniqueness: { scope: 'b', msg: 'good' }
      expect(Foo.create(a: -1).hasErrors()).toBe(false)
      expect(Foo.create(a: -1).hasErrors()).toBe(true)
      expect(Foo.create(a: -1, b: 1).hasErrors()).toBe(false)
      f = Foo.create(a: -1, b: 1)
      expect(f.hasErrors()).toBe(true)
      expect(f.errors()).toEqual({ a: ['good']})
      expect(Foo.count()).toBe(2)