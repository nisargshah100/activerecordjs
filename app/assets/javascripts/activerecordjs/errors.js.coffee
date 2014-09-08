class RecordInvalid extends Error

  constructor: (@errors) ->
    @message = "Record invalid: #{JSON.stringify(@errors)}"

  name: 'RecordInvalid'

ARJS.Errors = {}
ARJS.Errors.RecordInvalid = RecordInvalid
