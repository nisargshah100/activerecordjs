#= require application

describe 'Validation', ->

  it 'presence validator', ->
    v = ARJS.Validation.rules.presence()
    expect(v.validate('')).toBe(false)
    expect(v.validate(null)).toBe(false)
    expect(v.validate(undefined)).toBe(false)
    expect(v.validate('a')).toBe(true)

  it 'format', ->
    expect(ARJS.Validation.rules.format('abc').validate('abc')).toBe(true)
    expect(ARJS.Validation.rules.format('123').validate(123)).toBe(true)
    expect(ARJS.Validation.rules.format('true').validate(true)).toBe(true)
    expect(ARJS.Validation.rules.format('false').validate(false)).toBe(true)
    expect(ARJS.Validation.rules.format(/^foo/).validate('foo')).toBe(true)
    expect(ARJS.Validation.rules.format(/^foo$/).validate('foo')).toBe(true)
    expect(ARJS.Validation.rules.format(/amazing/).validate('ama')).toBe(false)
    expect(ARJS.Validation.rules.format(/[a-z]{4}/).validate('good')).toBe(true)
    expect(ARJS.Validation.rules.format(/[a-z]{4}/).validate('gOod')).toBe(false)

  it 'email', ->
    expect(ARJS.Validation.rules.email().validate('abc')).toBe(false)
    expect(ARJS.Validation.rules.email().validate('apples@apples.com')).toBe(true)
    expect(ARJS.Validation.rules.email().validate('apples+good@apples.com')).toBe(true)
    expect(ARJS.Validation.rules.email().validate('@apples.com')).toBe(false)
    expect(ARJS.Validation.rules.email().validate('apples.com')).toBe(false)
    expect(ARJS.Validation.rules.email().validate('testing@test.aaaa')).toBe(true)
    expect(ARJS.Validation.rules.email().validate(123)).toBe(false)

  it 'alpha', ->
    expect(ARJS.Validation.rules.alpha().validate('abc')).toBe(true)
    expect(ARJS.Validation.rules.alpha().validate('abcA')).toBe(true)
    expect(ARJS.Validation.rules.alpha().validate('abcA2')).toBe(false)
    expect(ARJS.Validation.rules.alpha().validate('abc@')).toBe(false)
    expect(ARJS.Validation.rules.alpha().validate('abczz_')).toBe(false)

  it 'alphanumeric', ->
    expect(ARJS.Validation.rules.alphanumeric().validate('abc')).toBe(true)
    expect(ARJS.Validation.rules.alphanumeric().validate('abc123')).toBe(true)
    expect(ARJS.Validation.rules.alphanumeric().validate('abcA123')).toBe(true)
    expect(ARJS.Validation.rules.alphanumeric().validate('abc@')).toBe(false)

  it 'numericality', ->
    n = ARJS.Validation.rules.numericality

    # normal number
    expect(n().validate(123)).toBe(true)
    expect(n().validate(-123)).toBe(true)
    expect(n().validate(123.3)).toBe(false)
    expect(n().validate('0.3.4')).toBe(false)

    # unsigned
    expect(n(unsigned: true).validate(123)).toBe(true)
    expect(n(unsigned: true).validate(-123)).toBe(false)
    expect(n(unsigned: true).validate(123.3)).toBe(false)
    expect(n(unsigned: true).validate('-32')).toBe(false)
    expect(n(unsigned: true).validate('-32-')).toBe(false)

    # float
    expect(n(allow_float: true).validate(123)).toBe(true)
    expect(n(allow_float: true).validate(123.4)).toBe(true)
    expect(n(allow_float: true).validate(-123.4)).toBe(true)
    expect(n(allow_float: true).validate('-123.4')).toBe(true)
    expect(n(allow_float: true).validate('-123.4.4')).toBe(false)
    expect(n(allow_float: true).validate('-123.a')).toBe(false)

    # unsigned & float
    expect(n(allow_float: true, unsigned: true).validate(123)).toBe(true)
    expect(n(allow_float: true, unsigned: true).validate(-123)).toBe(false)
    expect(n(allow_float: true, unsigned: true).validate(123.3)).toBe(true)
    expect(n(allow_float: true, unsigned: true).validate(-123.3)).toBe(false)

    # greater then check
    expect(n(greater_than: 10).validate(3)).toBe(false)
    expect(n(greater_than: 10).validate(-3)).toBe(false)
    expect(n(greater_than: 10).validate(10)).toBe(false)
    expect(n(greater_than: 10).validate('10')).toBe(false)
    expect(n(greater_than: 10).validate('11')).toBe(true)
    expect(n(greater_than: 10).validate(11)).toBe(true)

    # greater then or equal to
    expect(n(greater_than_or_equal_to: 10).validate(10)).toBe(true)
    expect(n(greater_than_or_equal_to: 10).validate('10')).toBe(true)
    expect(n(greater_than_or_equal_to: 10).validate(-10)).toBe(false)
    expect(n(greater_than_or_equal_to: 10).validate('-10')).toBe(false)

    # less than
    expect(n(less_than: 10).validate(10)).toBe(false)
    expect(n(less_than: 10).validate(-10)).toBe(true)
    expect(n(less_than: 10, unsigned: true).validate(-10)).toBe(false)

    # less than or equal to
    expect(n(less_than_or_equal_to: 10).validate(10)).toBe(true)
    expect(n(less_than_or_equal_to: 10).validate(-10)).toBe(true)
    expect(n(less_than_or_equal_to: 10).validate('10.0')).toBe(false)
    expect(n(less_than_or_equal_to: 10, allow_float: true).validate('10.0')).toBe(true)

    # equal to
    expect(n(equal_to: 10).validate(10)).toBe(true)
    expect(n(equal_to: 10).validate(-10)).toBe(false)
    expect(n(equal_to: 10).validate(11)).toBe(false)
    expect(n(equal_to: 10).validate(9)).toBe(false)
    expect(n(equal_to: 10).validate('10')).toBe(true)
    expect(n(equal_to: 10).validate('10.0')).toBe(false)
    expect(n(equal_to: 10, allow_float: true).validate('10.0')).toBe(true)

    # even
    expect(n(even: true).validate(10)).toBe(true)
    expect(n(even: true).validate(-10)).toBe(true)
    expect(n(even: true).validate(0)).toBe(true)
    expect(n(even: true).validate(1)).toBe(false)
    expect(n(even: true).validate('2.0')).toBe(false)
    expect(n(even: true, allow_float: true).validate('2.0')).toBe(true)
    expect(n(even: true, allow_float: true).validate('3.0')).toBe(false)

    # odd
    expect(n(odd: true).validate(9)).toBe(true)
    expect(n(odd: true).validate(10)).toBe(false)
    expect(n(odd: true).validate(-9)).toBe(true)
    expect(n(odd: true).validate(-10)).toBe(false)
    expect(n(odd: true).validate('9.0')).toBe(false)
    expect(n(odd: true, allow_float:true).validate('9.0')).toBe(true)
    expect(n(odd: true, allow_float:true).validate('-10.0')).toBe(false)

  it 'inclusion', ->
    v = ARJS.Validation.rules.inclusion
    expect(v([1, 2, 3]).validate(1)).toBe(true)
    expect(v([1, 2, 3]).validate(4)).toBe(false)
    expect(v([1, 2, 3]).validate('4')).toBe(false)
    expect(v(['a', 'b', 'c']).validate('c')).toBe(true)
    expect(v(['a', 'b', 'c']).validate('d')).toBe(false)
    expect(v({ within: ['a', 'b', 'c'] }).validate(null)).toBe(false)
    expect(v({ in: ['a', 'b', 'c'] }).validate(undefined)).toBe(false)

  it 'exclusion', ->
    v = ARJS.Validation.rules.exclusion
    expect(v([1, 2, 3]).validate(1)).toBe(false)
    expect(v([1, 2, 3]).validate(4)).toBe(true)
    expect(v([1, 2, 3]).validate('4')).toBe(true)
    expect(v(['a', 'b', 'c']).validate('c')).toBe(false)
    expect(v(['a', 'b', 'c']).validate('d')).toBe(true)
    expect(v({ within: ['a', 'b', 'c'] }).validate(null)).toBe(true)
    expect(v({ in: ['a', 'b', 'c'] }).validate(undefined)).toBe(true)

  it 'length', ->
    v = ARJS.Validation.rules.length

    # max
    expect(v(max: 3).validate('abc')).toBe(true)
    expect(v(max: 3).validate('abcd')).toBe(false)
    expect(v(max: 3).validate(null)).toBe(false)
    expect(v(max: 0).validate('a')).toBe(false)

    # min
    expect(v(min: 0).validate('abc')).toBe(true)
    expect(v(min: 5).validate('abcd')).toBe(false)
    expect(v(min: 5).validate(null)).toBe(false)
    expect(v(min: 5).validate('abcde')).toBe(true)
    expect(v(min: 5).validate('abcd')).toBe(false)

    # equals
    expect(v(equals: 5).validate('abcd')).toBe(false)
    expect(v(equals: 5).validate('abcdef')).toBe(false)
    expect(v(equals: 5).validate('abcde')).toBe(true)
    expect(v(equals: 5).validate(12345)).toBe(true)

    # within
    expect(v(within: [1..3]).validate('abc')).toBe(true)
    expect(v(within: [1..3]).validate('abcd')).toBe(false)
    expect(v(within: [1..3]).validate('a')).toBe(true)
    expect(v(within: [1..3]).validate('')).toBe(false)