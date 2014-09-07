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
  @setup 'users'  # first argument is the table name
  @schema (t) ->
    t.string('email')
    t.string('password')
    t.integer('age')
```

Thats it. The database and its underlying schema will be setup. We use Knex in order to generate the queries. In the above example, `t` is a Knex object.

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
  @setup 'users'
  @schema (t) ->
    t.string('email')
    t.string('password')
    t.string('token')
  
  @generateToken: ->
    @update_attributes({ token: ARJS.UUID() })
  
  # has to be below the method declaration since JS can't find it otherwise
  @afterCreate 'generateToken'
  
  # You can also specify function with the hooks
  @beforeSave ->
    console.log('hello world')
```

###### Infinite loop with hooks

There is a chance to get into an infinite loop with hooks. Lets take the above example. After the model is created, we call update attributes to save token. This update attributes does an update and so will call beforeSave, beforeUpdate, afterUpdate, afterSave hooks. In those hook, if you were to save / update again, you would have an infinite loop. 

OR 

This would be an infinite loop:

```
  @generateToken: ->
    @update_attributes({ token: ARJS.UUID() })

  @afterSave 'generateToken'
```

This is because after we save, we call generate token which calls beforeSave, beforeUpdate, afterUpdate, afterSave hooks. This would result in afterSave getting called over and over. 

So how you get past this? You can update / save by disabling hooks

```
  @afterSave ->
    @update_attributes({ blah: 1 }, { runHooks: false })
```

### Validation

There are bunch of validations supported and you can easily define custom validations as needed. 

Example:

```
class User
  @setup 'users'
  @schema (t) ->
    t.string('email')
    t.string('name')
    t.integer('age)
  
  @validates 'email', presence: true, email: true
  @validates 'name', length: { min: 4, max: 30, msg: 'name must be between 4 to 30 characters long' }
  @validates 'age', :numericality => { :greater_than_or_equal_to => 1, :less_than => 150 }

```

#### Supported Validations

* format
  * with: /regex/
* email
* alpha
* alphanumeric
* numericality
  * allow_float
  * unsigned (only positive numbers)
  * greater_than
  * less_than
  * greater_than_or_equal_to
  * less_than_or_equal_to
  * equal_to
  * odd
  * even
* inclusion
  * in / within (same just aliases)
* exclusion
  * in / within
* length
  * max
  * min
  * equals
  * within (ex/ within: [4..10])
 
###### Validation Error Message

You can provide a custom error message for each validation using `msg`. Example/ 

```
@validates 'email', presence: { msg: 'its required' }, email: { msg: 'invalid email' }, format: { with: /@/, msg: 'has to have @ symbol' }
```