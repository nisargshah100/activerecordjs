# NOT READY FOR USE YET

# ActiveRecordJS

A Javascript implementation similar to active record that runs completely in memory. This is useful for javascript applications that would like an orm to work with data.

##### Written in Coffeescript & all examples in coffeescript

### Namespace

ActiveRecordJS is encompassed in ARJS global. We rely on two other libraries - Knex & SQL.js which take up its own namespaces. 

### Thanks to

This project is only possible due to the awesome libraries that power ARJS. 

* https://github.com/kripken/sql.js/ (in memory sql implementation of sql for js)
* http://knexjs.org/ (query builder) 

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
```

#### Destroy Model


```
user = new User(email: 'a@a.com')
user.destroy()

# without callbacks
user.destroy({ runHooks: false })
```

#### reload model from db

```
user.reload()
```

#### update attributes is also available

```
user.updateAttributes({ email: 'c@c.com', password: 'boo' })
```

#### get hash from model

```
user.attrs()
```

#### Timestamps

If you want to model to be timestamped in javascript whenever created / updated, you can use:

```
class User
  @setup 'users', { timestamps: true }
```

This will add created_at & updated_at to your schema and add callbacks that update those values on create / update.

### Hooks

Hooks allow you run custom code at certain points in model execution. The following hooks are available:

* beforeSave (create / update)
* afterSave (create / update)
* beforeCreate
* afterCreate
* beforeUpdate
* afterUpdate
* afterInitialize
* beforeValidation
* afterValidation
* beforeDestroy
* afterDestroy

```
class User extends ARJS.Model
  @setup 'users'
  @schema (t) ->
    t.string('email')
    t.string('password')
    t.string('token')
  
  @generateToken: ->
    @updateAttributes({ token: ARJS.UUID() })
  
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
    @updateAttributes({ token: ARJS.UUID() })

  @afterSave 'generateToken'
```

This is because after we save, we call generate token which calls beforeSave, beforeUpdate, afterUpdate, afterSave hooks. This would result in afterSave getting called over and over. 

So how you get past this? You can update / save by disabling hooks

```
  @afterSave ->
    @updateAttributes({ blah: 1 }, { runHooks: false })
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
  
### saving a user that fails validation

user = User.create({ email: 'test' })
user.isSaved() # false
user.isNew() # true
user.errors() # set of errors { email: [ERRORS], name: [ERRORS] }

# Save is similar to create but returns true or false

user = new User({ email: 'test' })
user.save() # false
user.errors() # set of errors { email: [ERRORS], name: [ERRORS] }

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

##### Validation hooks


If you just want to run validation on create or update or destroy, you can use:

```
@validates 'email', presence: true, on: 'create'
@validates 'email', presence: true, on: 'update'
@validates 'email', presence: true, on: 'destroy'
@validates 'email', presence: true, on: 'save' # both create & update - default if none passed
```

### Custom Validations

You can provide your own validations via hooks. Example validation before creating:

```

class User extends ARJS.Model
  @setup 'users'
  @schema (t) ->
    t.string('email')
    t.string('password')
    t.string('token')
  
  @validateToken: ->
    if @token == '123'
      @addError('token', 'cant be 123')
  
  # has to be below the method declaration since JS can't find it otherwise
  @beforeCreate 'validateToken'


```

You can add validations to beforeCreate, beforeUpdate, beforeSave or beforeDestroy

## Quering

ARJS supports many ways to fetch data from database. 

The following methods are supported:

* all
* where
* first
* last
* offset
* limit
* distinct
* orderBy
* pluck
* groupBy
* having
* count

Fetch all records:

```
User.all()
```

Fetch all records where email is `foo`

```
User.where('email = ?', 'foo').all()
```

OR

```
User.where('email', 'foo').all()
```

Get first record where email is like `foo`

```
User.where('email LIKE ?', '%foo%').first()
```

Limit email like `foo` to 10 records offset 5

```
User.where('email LIKE ?', '%foo%').offset(5).limit(10).all()
```

Return distinct records for emails

```
User.distinct('email').all()
```

Pluck emails from all users

```
User.pluck('email') # returns array - ex/ [email1, email2, email3]
```

Group by email address

```
User.groupBy('email').all()
```

Group by having

```
User.groupBy('count').having('count', '>', 300).all()
```

Count 

```
User.count()
User.where('email = ?', 'foo').count()
```