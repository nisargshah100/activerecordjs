# Use with caution - there may be bugs still!

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

In active record, using `!` on save would raise an error instead of returning a boolean. Same can be achieved through:

```
user.saveOrError()
```

Above statement would throw a ARJS.Errors.RecordInvalid exception. It can be accessed like:

```
try
  user.saveOrError()
catch e
  if e.name == 'RecordInvalid'
    console.log e.errors         # handle this exception
    e.model.destroy()            # model refers to the instance that failed
  else
    throw e                      # some other error - lets throw it up further
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

user.updateAttributesOrError({ email: 'c@c.com', password: 'boo' })
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

#### Delete all models

To delete all models, there are destroyAll, destroyAllOrError & deleteAll methods.

destroy methods call all the hooks before deleting. If you have a validation on destroy, calling destroy would run the validation.

```
class User
  @setup 'users'
  @schema (t) -> t.string('name')
  @validates 'name', presence: true, on: 'destroy'

u = User.create()

User.destroyAll()           # returns false and doesn't destroy anything since one failed validation

User.destroyAllOrError()    # throws a RecordInvalid exception and doesn't delete anything

User.deleteAll()           # deletes all users without calling any callbacks
  
```

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

* uniqueness
  * scope
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
@validates 'email', presence: true, uniqueness: true, on: 'create'
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

## Transactions

Transactions are supported using Model.transcation block. 

```
try
  User.transaction ->
    User.createOrError(email: 'a@a.com')       # good
    User.createOrError(email: '')              # fails - missing email  
catch e
  e.name    # RecordInvalid
  e.errors  # { email: ['is required'] }
  e.model   # user object that failed creating

User.count()      # 0 since transaction failed
```

If you want to manually rollback transaction, you can throw any error in the transaction block

```
try
  User.transaction ->
    User.createOrError(email: 'a@a.com')     # good
    throw new Error('boo')
catch e
  # e = boo error

User.count()        # 0 since transaction failed
```

## Quering

ARJS supports many ways to fetch data from database. 

The following methods are supported:

* find
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

Find a single user

```
User.find({ email: 'a@a.com' })          # returns null / user
User.findOrError({ email: 'a@a.com' })") # throws ARJS.Errors.RecordNotFound / user
```


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

## Associations

We support many different kinds of associations. These incude:

* belongsTo
   * key
   * foreignKey
   * className
* hasMany
   * key
   * className
   * foreignKey
   * through

### Belongs To

If the current object belongs to another one and has an id for the other object, use this. Example/ book belongs to author. 

```
class Book
  @setup 'books'
  @belongsTo 'author'
  
  @schema (t) ->
  	t.string('name')
  	t.belongsTo('author_id')
```

Thats it. We assume a lot of stuff but everything is customizable. This relationship can be used like:

```
Book.first().author
```

The code above assumes you have a `author_id` key in the schema. You can change that using `key`

```
@belongsTo 'author', key: 'person_id'
```

It also assumes that we should look at author's `id`. That can be customized using:

```
@belongsTo 'author', key: 'person_id', foreignKey: '_id', className: 'User'
```

### Has Many

Opposite of belongs to relationship. The id attribute is on the foreign table. Example/

```
class Author
  @setup 'authors'
  @hasMany 'books'
  
  @schema (t) ->
    t.integer('my_id')
    t.string('name')
```

This can be accessed via:

```
Author.first().books()            # notice its a method unlike belongs to
```

We dont run a query to database when you use the above statement. It just returns a query builder so you can add more conditions to it. 

```
Author.first().books().where({ name: 'foo' }).orderBy('created_at DESC').all()
```

Again, just using `@hasMany 'books'` assumes a lot of stuff. That is customizable through `key`, `foreignKey`, and `className`

```
@hasMany 'books', key: 'my_id', foreignKey: 'user_id', className: 'Book'
```

#### Through Association

Through allows you to setup a many to many relationship. It goes through another model to the target model. 

Example:

```
class User extends ARJS.Model
  @setup 'users'
  @hasMany 'user_accounts'
  @hasMany 'accounts', through: 'user_accounts'
  @schema (t) ->
    t.string('email')

class UserAccount extends ARJS.Model
  @setup 'user_accounts'
  @belongsTo 'user'
  @belongsTo 'account'
  @schema (t) ->
    t.integer('user_id')
    t.integer('account_id)

class Account extends ARJS.Model
  @setup 'accounts'
  @schema (t) ->
    t.string('name')

```

Using this, you can query records like:

```
User.first().accounts().all()       # fetch all records
User.first().accounts().where('name = ?', 'apples').all()    # fetch all my accounts with the name apples
```