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
      foo.update_attributes(a: 2, b: 3)
      foo._refresh()
      expect(foo.a).toBe(2)
      expect(foo.b).toBe(3)

  describe 'hooks', ->
    Boo = null
    str = ''

    class Boo extends ARJS.Model
      @setup 'boos'
      @schema (t) -> 
        t.string('name')
        t.string('token')

    describe 'before save', ->

      Boo.bs = -> str += @name
      Boo.beforeSave 'bs'

      beforeEach ->
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

      # updates the token in a hook
      Boo.afterSave ->
        @update_attributes({ token: ARJS.UUID() }, runHooks: false)

      it 'updates the token in after save hook', ->
        boo = new Boo(name: 'Cool')
        expect(boo.token).toEqual(undefined)
        boo.save()
        expect(boo.token).not.toEqual(undefined)

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
      f.update_attributes(name: 'apple2')
      expect(x).toBe(2)

    it 'after update gets called', ->
      x = 0
      Boo.afterUpdate -> x += 1
      f = new Boo(name: 'apples')
      f.save()
      expect(x).toBe(0)
      f.update_attributes(name: 'apples2')
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
      expect(Voo._validationRules.email[0].message()).toEqual('boo yeah')

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