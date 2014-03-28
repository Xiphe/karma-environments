describe 'environment controller', ->
  di                    = require 'di'
  KarmaEnvironment      = require lib 'KarmaEnvironment'
  EnvironmentController = require lib 'EnvironmentController'

  i = 1
  injector = null

  afterEach ->
    i = 1

  fakeEnv = (name = 'FakeEnv') ->
    env = injector.instantiate KarmaEnvironment
    env.name = "#{name}#{i++}"
    env.run = sinon.spy()
    env._tests = ['foo']
    env

  it 'should exist', ->
    expect(EnvironmentController).to.exist

  setupEnvironmentsFake = (n = 3) ->
    return @setupPromise if @_setupTriggered
    @_setupTriggered = true

    for i in [1..n]
      @environments.push fakeEnv()

    @_setupDeferred.resolve()
    @setupPromise

  describe 'EnvironmentController', ->
    envCtrl = null

    setupFakeEnvironments = ->
      envCtrl.setupEnvironments = setupEnvironmentsFake
      envCtrl.setupEnvironments()

    beforeEach ->
      injector = new di.Injector [
        constants: ['value', require lib 'constants']
        logger: ['type', require fake 'Logger']
        config: ['value', require fake 'config']
        runner: ['value', require fake 'Runner']
      ]
      envCtrl = injector.instantiate EnvironmentController

    describe 'instantiation', ->
      it 'should have an instance', ->
        expect(envCtrl).to.be.an.instanceof EnvironmentController

      it 'should have an array of env. file matchers', ->
        expect(envCtrl.getDefinitionMatchers()).to.be.an.instanceof Array

      it 'should take definitions from config', ->
        expect(envCtrl.getDefinitionMatchers()).to.contain 'foobar'

      it 'should not know any environments by instantiation.', ->
        expect(envCtrl.environments.length).to.equal 0

    describe 'environment running', ->
      it 'should use run() when we call runAll()', ->
        sinon.stub(envCtrl, 'run')
        envCtrl.runAll()
        expect(envCtrl.run).to.have.been.called

      it 'should start to search for environments when we want to run some.', ->
        stub = ->
        sinon.stub(envCtrl, 'setupEnvironments').returns then: stub, catch: stub
        envCtrl.run()
        expect(envCtrl.setupEnvironments).to.have.been.called

      it 'should execute all run methods of environments', (done) ->
        envCtrl.setupEnvironments = setupEnvironmentsFake
        envCtrl.runAll().then ->
          for i in [0..2]
            expect(envCtrl.environments[i].run).to.have.been.called
          done()

      it 'should execute only the environment we want to', (done) ->
        setupFakeEnvironments()
        envCtrl.run([envCtrl.environments[1]]).then ->
          expect(envCtrl.environments[0].run).not.to.have.been.called
          expect(envCtrl.environments[1].run).to.have.been.called
          expect(envCtrl.environments[2].run).not.to.have.been.called
          done()

      it 'should execute a passed callback before the last environment will run', (done) ->
        setupFakeEnvironments()
        test = ''
        envCtrl.environments[1].run = -> test += 'a'
        envCtrl.environments[2].run = -> test += 'c'
        envCtrl.runAll ->
          test += 'b'
        .then ->
          expect(test).to.equal 'abc'
          done()

    describe 'filter environments', ->
      it 'should sort environment definitions by name length', ->
        envCtrl.environmentDefinitions = ['foo', 'lorem', 'a', 'bc']
        envCtrl.sortDefinitions()
        for name, i in ['a', 'bc', 'foo', 'lorem']
          expect(envCtrl.environmentDefinitions[i]).to.equal name

      it 'should provide a list with environments containing a specific file', ->
        setupFakeEnvironments()
        for i in [0..2]
          envCtrl.environments[i].hasFile = sinon.stub().returns i == 1
        environmentsWithFile = envCtrl.getEnvironmentsByFile('foo')

        for i in [0..2]
          expect(envCtrl.environments[i].hasFile).to.have.been.called
        expect(environmentsWithFile).to.deep.equal [envCtrl.environments[1]]

      it 'should provide a list of environments that are active', ->
        setupFakeEnvironments()
        envCtrl.environments[0]._active = false
        envCtrl.environments[1]._active = false
        expect(envCtrl.getActiveEnvironments().length).to.equal 1

      it 'should provide a list of environments that are testable', ->
        setupFakeEnvironments()
        envCtrl.environments[2]._tests = []
        expect(envCtrl.getEnvironmentsWithTests().length).to.equal 2

      it 'should deactivate other environments if one has focus', ->
        setupFakeEnvironments()
        envCtrl.environments[0]._focus = true
        envCtrl.handleFocus()
        for i in [1..2]
          expect(envCtrl.environments[i]._active).to.equal false
        expect(envCtrl.environments[0]._active).to.equal true
