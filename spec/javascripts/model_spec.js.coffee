#= require application

Foo = null

describe 'Model', ->

  beforeEach ->
    class Foo extends ARJS.Model
      @tableName = 'foos'
      @schema (t) ->
        t.integer('a')
        t.integer('b')

  afterEach ->
    ARJS.exec('drop table foos')

  it 'creates a table', ->
    expect(Foo.isTableCreated()).toBe(true)

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

    describe 'before save', ->
      Boo = null
      str = null

      class Boo extends ARJS.Model
        @tableName = 'boos'
        @schema (t) -> t.string('name')
        @lol = -> str += @name
        @beforeSave 'lol'

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


    it 'after initialize gets called', ->
      x = 0
      Foo.afterInitialize -> x += 1
      new Foo(a: 1)
      expect(x).toBe(1)

    it 'before update gets called', ->
      x = 0
      Foo.beforeUpdate -> x += 1
      f = new Foo(a: 1)
      f.save()
      expect(x).toBe(0)
      f.a = 2
      f.save()
      expect(x).toBe(1)
      f.update_attributes(a: 10, b: 3)
      expect(x).toBe(2)