describe 'base', ->
  Q         = require 'q'
  di        = require 'di'
  Base      = require lib 'Base'
  FakeClass = require fake 'Class'

  class Fixture extends Base
    constructor: -> super

  Fixture.$inject = Base.$inject.concat ['fake']

  injector = null

  describe 'Base', ->
    beforeEach ->
      injector = new di.Injector [
        logger: ['type', require fake 'Logger']
        config: ['value', require fake 'config']
        constants: ['value', require lib 'constants']
        fake: ['type', FakeClass]
      ]

    it 'should exist.', ->
      expect(Base).to.exist

    it 'should have a setup method', ->
      expect(Base.prototype.__setup).to.exist

    it 'should apply dependencies to our new instances.', ->
      fixture = injector.instantiate Fixture
      expect(fixture.fake).to.be.an.instanceof FakeClass

    it 'should create a logger on the fixture', ->
      fixture = injector.instantiate Fixture
      expect(fixture.logger).to.exist

    it 'should call FakeLoggers create method to create the logger', ->
      createSpy = sinon.spy()
      logger = injector.get 'logger'
      logger.create = createSpy
      fixture = injector.instantiate Fixture
      expect(createSpy).to.have.been.called

    describe '_runQueue', ->
      d = null
      queue = null
      _runQueue = Base.prototype._runQueue

      beforeEach ->
        d = Q.defer()
        queue = []

      it 'should execute a list of functions', (done) ->
        fixture = ''
        queue.push -> fixture += 'a'
        queue.push -> fixture += 'b'
        _runQueue(queue).then ->
          expect(fixture).to.equal 'ab'
          done()

      it 'should handle deferred functions', (done) ->
        fixture = ''
        queue.push -> fixture += 'a'
        queue.push ->
          setTimeout ->
            fixture += 'b'
            d.resolve()
          , 5
          d.promise
        queue.push -> fixture += 'c'

        _runQueue(queue).then ->
          expect(fixture).to.equal 'abc'
          done()

      it 'should reject if a deferred fails', (done) ->
        fixture = ''
        queue.push -> fixture += 'a'
        queue.push ->
          setTimeout ->
            d.reject 'error'
          , 5
          d.promise
        queue.push -> fixture += 'c'

        _runQueue(queue).catch (error) ->
          expect(fixture).to.equal 'a'
          expect(error).to.equal 'error'
          done()

      it 'should use a passed deferred object, if present', (done) ->
        _runQueue queue, d
        d.promise.then done


    describe '__setup', ->
      fakeInstance = null
      __setup = null

      beforeEach ->
        __setup = Base.prototype.__setup
        fakeInstance =
          config: {}
          constants:
            DEFAULTS: {}

      it 'should not execute twice', ->
        expect(__setup.call(fakeInstance)).to.be.instanceof Object
        expect(__setup.call(fakeInstance)).to.equal undefined

      it 'should execute twice if the configuration changed', ->
        expect(__setup.call(fakeInstance)).to.be.instanceof Object
        fakeInstance.config.environments = some: 'other object'
        expect(__setup.call(fakeInstance)).to.be.instanceof Object

      it 'should not execute twice if we manipulate the configuration', ->
        expect(__setup.call(fakeInstance)).to.be.instanceof Object
        fakeInstance.config.environments.foo = 'bar'
        expect(__setup.call(fakeInstance)).to.equal undefined

      it 'should set environment key into configuration', ->
        __setup.call(fakeInstance)
        expect(fakeInstance.config.environments).to.exist

      it 'should apply defaults to configuration', ->
        fakeInstance.constants.DEFAULTS.foo = 'bar'
        fakeInstance.constants.DEFAULTS.yo = ['lo']
        __setup.call(fakeInstance)
        expect(fakeInstance.config.environments.foo).to.equal 'bar'
        expect(fakeInstance.config.environments.foo).to.equal 'bar'
        expect(fakeInstance.config.environments.yo).to.deep.equal ['lo']

      it 'should ensure arrays where needed', ->
        fakeInstance.constants.DEFAULTS.lorem = ['ipsum']
        fakeInstance.config.environments = lorem: 'dolor'
        __setup.call(fakeInstance)
        expect(fakeInstance.config.environments.lorem).to.deep.equal ['dolor']

      it 'should leave non-arrays intact', ->
        fakeInstance.config.environments = mooh: 'wuff'
        __setup.call(fakeInstance)
        expect(fakeInstance.config.environments.mooh).to.equal 'wuff'
