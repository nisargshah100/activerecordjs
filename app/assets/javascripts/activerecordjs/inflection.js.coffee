###
Copyright (c) 2012 Ryan Scott Lewis (ryanscottlewis@gmail.com)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
###

###
This lets us detect if an Array contains a given element in IE < 9
Signature:
  Array.indexOf(item, fromIndex, compareFunc) == Integer
Arguments:
  item - Object - object to locate in the Array
  fromIndex - Integer (optional) - starts checking from this position in the Array
  compareFunc - Function (optional) - function used to compare Array item vs passed item
Returns:
  Integer - index position in the Array of the passed item
Examples:
  ['hi','there'].indexOf("guys") === -1
  ['hi','there'].indexOf("hi") === 0
###
unless Array::indexOf?
  Array::indexOf = (item, fromIndex, compareFunc) ->
    fromIndex = -1 unless fromIndex?
    index = -1
    
    for i in [fromIndex..this.length]
      if this[i] == item || compareFunc && compareFunc(this[i], item)
        index = i
        break
    
    index

###
This sets up some constants for later use
This should use the window namespace variable if available
###

InflectionCoffee =
  rules:
    ### These rules translate from the singular form of a noun to its plural form. ###
    plural: [
      ['goose$',                 'geese'],
      ['cow$',                   'kine'],
      ['(sex)$',                 '$1es'],
      ['(child)$',               '$1ren'],
      ['(m)an$',                 '$1en'],
      ['(pe)rson$',              '$1ople'],
      ['(quiz)$',                '$1zes'],
      ['^(oxen)$',               '$1en'],
      ['^(ox)$',                 '$1en'],
      ['([ml])ouse$',            '$1ice'],
      ['([ml])ice$',             '$1ice'],
      ['(matr|vert|ind)ix|ex$',  '$1ices'],
      ['(x|ch|ss|sh)$',          '$1es'],
      ['([^aeiouy]|qu)y$',       '$1ies'],
      ['(?:([^f])fe|([lr])f)$',  '$1$2ves'],
      ['sis$',                   'ses'],
      ['([ti])um$',              '$1a'],
      ['([ti])a$',               '$1a'],
      ['(buffal|tomat|potat)o$', '$1oes'],
      ['(bu)s$',                 '$1ses'],
      ['(alias|status|sex)$',    '$1es'],
      ['(octop|vir)us$',         '$1i'],
      ['(octop|vir)$',           '$1i'],
      ['(ax|test)is$',           '$1es'],
      ['s$',                     's'],
      ['$',                      's'],
    ]
    ### These rules translate from the plural form of a noun to its singular form. ###
    singular: [
      ['(database)s',                                                         '$1'],
      ['(quiz)zes$',                                                          '$1'],
      ['(matr)ices$',                                                         '$1ix'],
      ['(vert|ind)ices$',                                                     '$1ex'],
      ['^(ox)en',                                                             '$1'],
      ['(alias|status)(es)?$',                                                '$1'],
      ['(octop|vir)(us|i)$',                                                  '$1us'],
      ['^(a)x[ie]s$',                                                         '$1xis'],
      ['(cris|test)(is|es)$',                                                 '$1is'],
      ['(shoe)s$',                                                            '$1'],
      ['(o)es$',                                                              '$1'],
      ['(bus)(es)?$',                                                         '$1'],
      ['^(m|l)ice$',                                                          '$1ouse'],
      ['(x|ch|ss|sh)es$',                                                     '$1'],
      ['(s)eries$',                                                           '$1eries'],
      ['(m)ovies$',                                                           '$1ovie'],
      ['([^aeiouy]|qu)ies$',                                                  '$1y'],
      ['([lr])ves$',                                                          '$1f'],
      ['(hive)s$',                                                            '$1'],
      ['(tive)s$',                                                            '$1'],
      ['([^f])ves$',                                                          '$1fe'],
      ['(^analy)(sis|ses)$',                                                  '$1sis'],
      ['((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)(sis|ses)$', '$1$2sis'],
      ['([ti])a$',                                                            '$1um'],
      ['(n)ews$',                                                             '$1ews'],
      ['(ss)$',                                                               '$1'],
      ['s$',                                                                  '']
    ]
    ###
      This is a helper method that applies rules based replacement to a String
      Signature:
        InflectionJS.apply_rules(str, rules, skip, override) == String
      Arguments:
        str - String - String to modify and return based on the passed rules
        rules - Array: [RegExp, String] - Regexp to match paired with String to use for replacement
        skip - Array: [String] - Strings to skip if they match
        override - String (optional) - String to return as though this method succeeded (used to conform to APIs)
      Returns:
        String - passed String modified by passed rules
      Examples:
        InflectionJS.apply_rules("cows", InflectionJs.singular_rules) === 'cow'
    ###
    apply: (str, rules, override) ->
      return override if override
      ignore = ( InflectionCoffee.words.uncountable.indexOf( str.toLowerCase() ) > -1 )
      
      unless ignore
        for rule in rules
          rule[0] = new RegExp( rule[0], 'gi' ) unless rule[0] instanceof RegExp
          
          return str.replace( rule[0], rule[1] ) if str.match( rule[0] )
      
      str
  words:
    ### This is a list of downcased nouns that use the same form for both singular and plural. ###
    uncountable: ['equipment', 'information', 'rice', 'money', 'species', 'series', 'fish', 'sheep', 'jeans', 'police', 'deer']
    ### This is a list of words that should not be capitalized for title case ###
    non_titlecased: ['and', 'or', 'nor', 'a', 'an', 'the', 'so', 'but', 'to', 'of', 'at', 'by', 'from', 'into', 'on', 'onto', 'off', 'out', 'in', 'over', 'with', 'for']
  ### These are regular expressions used for converting between String formats ###
  regex:
    id_suffix: new RegExp('(_ids|_id)$', 'g')
    underbar: new RegExp('_', 'g')
    space_or_underbar: new RegExp('[\ _]', 'g')
    uppercase: new RegExp('([A-Z])', 'g')
    underbar_prefix: new RegExp('^_')

InflectionCoffee.singularize = (override) -> InflectionCoffee.rules.apply( override, InflectionCoffee.rules.singular )
InflectionCoffee.pluralize = (override) -> InflectionCoffee.rules.apply( override, InflectionCoffee.rules.plural )
InflectionCoffee.camelize = (override, lowercaseFirstLetter) ->
  string = override.toLowerCase()
  str_path = string.split('/')
  for path, i in str_path
    str_arr = path.split('_')
    initX = if lowercaseFirstLetter && i+1 == str_path.length then 1 else 0
    for x in [initX...str_arr.length]
      str_arr[x] = str_arr[x].charAt(0).toUpperCase() + str_arr[x].substring(1)
    str_path[i] = str_arr.join('')
  str_path.join('::')

InflectionCoffee.classify = (override) ->
  InflectionCoffee.singularize(InflectionCoffee.camelize(override))

ARJS.Inflection = InflectionCoffee