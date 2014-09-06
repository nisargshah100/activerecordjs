#= require application

class Foo extends ARJS.Model
  @tableName = 'foos'
  @schema (t) ->
    t.integer('a')
    t.integer('b')

describe 'Model', ->

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