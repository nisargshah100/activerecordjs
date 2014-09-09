describe 'Contacts', ->

  # A mini application to test bunch of functionality
  class ContactUser extends ARJS.Model
    @setup 'contact_users', { timestamps: true }
    @hasMany 'phones', className: 'ContactPhone', foreignKey: 'user_id'
    @schema (t) ->
      t.increments('id').index()
      t.string('name')

  class ContactPhone extends ARJS.Model
    @setup 'contact_phones', { timestamps: true }
    @belongsTo 'user', className: 'ContactUser', key: 'user_id'
    @schema (t) ->
      t.increments('id').index()
      t.string('number')
      t.integer('user_id')

  for x in [0...10]
    u = ContactUser.create(name: "User #{x}")
    for y in [0...10]
      ContactPhone.create(user: u, number: "123-123-123#{y}")


  it 'created stuff properly', ->
    expect(ContactUser.count()).toBe(10)
    expect(ContactPhone.count()).toBe(100)
    expect(ContactUser.first().phones().count()).toBe(10)
    expect(ContactPhone.first().user).not.toBe(null)
    expect(ContactUser.first().phones().orderBy('created_at DESC').first().number).toEqual('123-123-1239')

