class FakeBridge
  constructor: ->
    @doneCallbacks = []
    @originalConfigFiles = ['abc.js']
  setFrameworks: ->
  getPatterns: (files) ->
    files

module.exports = FakeBridge