# NOT READY FOR USE YET

# ActiveRecordJS

A Javascript implementation similar to active record that runs completely in memory. This is useful for javascript applications that would like an orm to work with data.

##### Written in Coffeescript & all examples in coffeescript

### Namespace

ActiveRecordJS takes up 3 global namespaces. The three namespaces are SQL, Knex & ARJS. 

-------------


#### Define a model & setup its schema

```
class User extends ARJS.Model
  @tableName = 'users'
  @schema (t) ->
    t.string('email')
    t.string('password')
    t.integer('age')
```

Thats it. The database and its underlying database will be setup. We use Knex in order to generate the queries. In the above example, `t` is a Knex object.

See: http://knexjs.org/#Schema-createTable

#### Access & set attributes once model is created

```
  user = new Foo(email: 'a@a.com')
  user.email
  user.email = 'b@b.com'
```

#### Saving & Updating Model

```
user = new User(email: 'email@email.com')
user.save()
user.password = 'foobar'
user.save()

# update attributes is also available
user.update_attributes({ email: 'c@c.com', password: 'boo' })
```

#### Hooks

Hooks allow you run custom code at certain points in model execution. The following hooks are available:

* beforeSave (create / update)
* afterSave (create / update)
* beforeCreate
* afterCreate
* beforeUpdate
* afterUpdate
* afterInitialize

```
class User extends ARJS.Model
  @tableName 'users'
  @schema (t) ->
    t.string('email')
    t.string('password')
    t.string('token')
  
  @generateToken: ->
    @update_attributes({ token: ARJS.UUID() })
  
  # has to be below the method declaration since JS can't find it otherwise
  @afterSave: 'generateToken'
  
  # You can also specify function with the hooks
  @beforeSave ->
    console.log('hello world')
```