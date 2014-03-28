require 'coffee-errors'

sinon        = require 'sinon'
chai         = require 'chai'
path         = require 'path'
basePath     = process.cwd()
libDir       = path.join basePath, 'lib'
fakeDir      = path.join basePath, 'test/unit/fake'

#* publish globals that all specs can use
global.expect      = chai.expect
global.sinon       = sinon
global.should      = chai.should()
global.lib         = (name) ->
  path.join libDir, name
global.fake        = (name) ->
  path.join fakeDir, name

#* chai plugins
chai.use require 'chai-as-promised'
chai.use require 'sinon-chai'

beforeEach ->
  global.sinon = sinon.sandbox.create()

afterEach ->
  sinon.restore()
