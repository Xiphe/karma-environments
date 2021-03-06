describe 'environment runner', ->
  Q                 = require 'q'
  di                = require 'di'
  path              = require 'path'
  EnvironmentRunner = require lib 'EnvironmentRunner'

  it 'should exist', ->
    expect(EnvironmentRunner).to.exist

  describe 'EnvironmentRunner', ->
    runner = null
    injector = null

    beforeEach ->
      injector = new di.Injector [
        constants: ['value', require lib 'constants']
        logger: ['type', require fake 'Logger']
        config: ['value', require fake 'config']
        bridge: ['type', require fake 'Bridge']
        executor: ['type', require fake 'Executor']
        fileList: ['value', require fake 'fileList']
      ]
      runner = injector.instantiate EnvironmentRunner

    it 'should have an instance', ->
      expect(runner).to.be.instanceof EnvironmentRunner

    describe 'run', ->
      it 'should restore original config files before run', ->
        config = injector.get 'config'
        config.files = ['false']
        runner.run()
        expect(config.files).to.deep.equal ['abc.js']

      it 'should call bridge.setFrameworks', ->
        bridge = injector.get 'bridge'
        bridge.setFrameworks = sinon.spy()
        frameworks = ['my framework']
        runner.run frameworks
        expect(bridge.setFrameworks).to.have.been.calledWith frameworks

      it 'should call fileList.reload', ->
        fileList = injector.get 'fileList'
        fileList.reload = sinon.stub().returns Q.all []
        runner.run [], ['myLib.js', 'myTest.coffee']
        expect(fileList.reload).to.have.been.called
        expect(fileList.reload.getCall(0).args[0]).to.contain 'abc.js'
        expect(fileList.reload.getCall(0).args[0]).to.contain 'myLib.js'
        expect(fileList.reload.getCall(0).args[0]).to.contain 'myTest.coffee'

      it 'should add hook.js to env', ->
        hookJs = path.resolve __dirname, '../../../lib/src/hook.js'
        fileList = injector.get 'fileList'
        fileList.reload = sinon.stub().returns Q.all []
        runner.run [], []
        expect(fileList.reload.getCall(0).args[0]).to.contain hookJs


      it 'should schedule the executor', (done) ->
        executor = injector.get 'executor'
        executor.schedule = sinon.spy()
        runner.run()
        setTimeout =>
          expect(executor.schedule).to.have.been.called
          done()
        , 5

      it 'should pass done callbacks to the bridge, if present', ->
        runner.run [], [], ->
        expect(injector.get('bridge').doneCallbacks.length).to.equal 1


