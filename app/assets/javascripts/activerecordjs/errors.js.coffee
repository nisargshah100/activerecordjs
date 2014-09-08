class RecordNotFound extends Error
  constructor: (@args) ->
    @message = "Couldn't find record: #{JSON.stringify(@args)}"
  name: 'RecordNotFound'

class RecordInvalid extends Error

  constructor: (@errors, @model = null) ->
    @message = "Record invalid: #{JSON.stringify(@errors)}"

  name: 'RecordInvalid'

ARJS.Errors = {}
ARJS.Errors.RecordInvalid = RecordInvalid
ARJS.Errors.RecordNotFound = RecordNotFound
