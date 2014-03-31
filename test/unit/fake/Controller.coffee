Q = require 'q'

class FakeController
  getEnvironmentsWithTests: -> [1,2,3]
  runEnvironmentsByFile: -> Q.all []
  runAll: -> Q.all []

module.exports = FakeController