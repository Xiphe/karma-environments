describe 'karma bridge', ->
  Q          = require 'q'
  _          = require 'lodash'
  di         = require 'di'
  path       = require 'path'
  proxyquire = require 'proxyquire'

  watcherStub = {}
  fakePattern = foo: 'bar', pattern: 'foo.js'
  configStub  = createPatternObject: sinon.stub().returns fakePattern
  karmaDir    = path.join process.cwd(), 'node_modules/karma'
  watcherPath = path.join karmaDir, 'lib/watcher'
  configPath  = path.join karmaDir, 'lib/config'
  doneStub    = ->
  stubs       = {}
  stubs[watcherPath] = watcherStub
  stubs[configPath] = configStub
  KarmaBridge = proxyquire.noCallThru() lib('KarmaBridge'), stubs

  getFileList = ->
    foo: [
      { originalPath: 'bar', mtime: 'Tue Mar 11 2014 22:51:29 GMT+0100 (CET)' }
      { originalPath: 'baz', mtime: 'Sun Jul 21 2013 02:12:51 GMT+0200 (CEST)' }
      { originalPath: 'foo', mtime: 'Sun Mar 23 2014 19:07:47 GMT+0100 (CET)' }
      { originalPath: 'baf', mtime: 'Sun Jul 21 2013 02:12:51 GMT+0200 (CEST)' }
    ]

  it 'should exist', ->
  expect(KarmaBridge).to.exist

  describe 'KarmaBridge', ->
    bridge = null
    injector = null

    beforeEach ->
      injector = new di.Injector [
        constants: ['value', require lib 'constants']
        logger: ['type', require fake 'Logger']
        config: ['value', require fake 'config']
        controller: ['type', require fake 'Controller']
        fileList: ['value', require fake 'fileList']
        emitter: ['type', require fake 'Emitter']
        launcher: ['type', require fake 'Launcher']
        socketServer: ['type', require fake 'SocketServer']
        webServer: ['type', require fake 'WebServer']
        done: ['value', -> doneStub.apply doneStub, arguments]
      ]
      bridge = injector.instantiate KarmaBridge

    it 'should have an instance', ->
      expect(bridge).to.be.instanceof KarmaBridge

    describe 'init', ->
      config = null
      emitter = null
      beforeEach ->
        config = injector.get 'config'
        emitter = injector.get 'emitter'
        emitter.on = sinon.spy()
        config.singleRun = true
        config.autoWatch = true
        bridge.init()


      it 'should deactivate singleRun in config', ->
        expect(config.singleRun).to.equal false

      it 'should deactivate autoWatch in config', ->
        expect(config.autoWatch).to.equal false

      it 'should register a run_complete listener', ->
        expect(emitter.on).to.have.been.calledWith 'run_complete', bridge.runComplete

      it 'should register a file_list_modified listener', ->
        expect(emitter.on).to.have.been.calledWith 'file_list_modified', bridge.fileListModified

      it 'should register a browser_register listener', ->
        expect(emitter.on).to.have.been.calledWith 'browser_register', bridge.browserRegister

    describe 'setFrameworks', ->
      originalGet = null
      originalFiles = null
      config = null

      beforeEach ->
        originalGet = injector.get
        config = injector.get 'config'
        originalFiles = _.clone config.files
        i = 0
        injector.get = ->
          config.files.push "foo#{i++}.js"

      afterEach ->
        injector.get = originalGet
        config.files = originalFiles

      it 'should add frameworks to config.files', ->
        bridge.setFrameworks ['foo']
        expect(config.files).to.contain 'foo0.js'

      it 'should add multiple frameworks to config.files', ->
        bridge.setFrameworks ['foo', 'bar']
        expect(config.files).to.contain 'foo0.js'
        expect(config.files).to.contain 'foo1.js'

      it 'should call injector.get with each framework', ->
        injector.get = sinon.spy()
        bridge.setFrameworks ['foo', 'bar']
        expect(injector.get).to.have.been.called.twice
        expect(injector.get).to.have.been.calledWith 'framework:foo'
        expect(injector.get).to.have.been.calledWith 'framework:bar'

      it 'should cache framework files internally', ->
        bridge.setFrameworks ['foo', 'bar']
        expect(bridge.frameworkCache.foo).to.deep.equal ['foo0.js']
        expect(bridge.frameworkCache.bar).to.deep.equal ['foo1.js']

      it 'should not call injector.get if framework is cached', ->
        bridge.frameworkCache.foo = ['foo-1.js']
        injector.get = sinon.spy()
        bridge.setFrameworks ['foo']
        expect(injector.get).not.to.have.been.called

    describe 'getPatterns', ->
      beforeEach ->
        configStub.createPatternObject.reset()

      it 'should convert an array of patterns into an array of objects', ->
        expect(bridge.getPatterns(['foo.js'])).to.deep.equal [fakePattern]

      it 'should call config.createPatternObject in order to do so', ->
        bridge.getPatterns ['foo.js']
        expect(configStub.createPatternObject).to.have.been.called

      it 'should cache files in allFiles', ->
        bridge.getPatterns ['foo.js']
        expect(bridge.allFiles).to.deep.equal ['foo.js']

      it 'should cache created patterns', ->
        bridge.getPatterns ['foo.js']
        expect(bridge.allPatternObjects).to.deep.equal [fakePattern]

      it 'should not create a new pattern if it is in cache', ->
        bridge.allFiles = ['foo.js']
        bridge.getPatterns ['foo.js']
        expect(configStub.createPatternObject).not.to.have.been.called

    describe 'runAll', ->
      controller = null

      beforeEach ->
        controller = injector.get 'controller'
        controller.runAll = sinon.stub().returns Q.all []

      it 'should call controllers runAll method', ->
        bridge.runAll()
        expect(controller.runAll).to.have.been.called

      it 'should call startWatching when done', (done) ->
        bridge.startWatching = sinon.spy()
        bridge.runAll()
        setTimeout ->
          expect(bridge.startWatching).to.have.been.called
          done()
        , 0

    describe 'startWatching', ->
      fileList = null
      config = null

      beforeEach ->
        config = injector.get('config')
        bridge.originalAutoWatch = true
        fileList = injector.get 'fileList'
        fileList.reload = sinon.stub().returns Q.all []

      it 'should apply allPatternObjects to config files, because we want to watch all environments', ->
        pattern = foo: 'bar'
        bridge.allPatternObjects = [pattern]
        bridge.startWatching()
        expect(config.files).to.deep.equal ['abc.js', pattern]

      it 'should reload the file list with all files we have added', ->
        bridge.startWatching()
        expect(fileList.reload).to.have.been.calledWith config.files, config.exclude

      it 'should do nothing if originalAutoWatch is false', ->
        bridge.originalAutoWatch = false
        bridge.startWatching()
        expect(fileList.reload).not.to.have.been.called

      it 'should invoke the watcher', (done) ->
        injector.invoke = sinon.spy()
        bridge.startWatching()
        setTimeout ->
          expect(injector.invoke).to.have.been.called
          done()
        , 0

      it 'should invoke the watcher only once', (done) ->
        injector.invoke = sinon.spy()
        bridge.startWatching()
        setTimeout ->
          bridge.startWatching()
          setTimeout ->
            expect(injector.invoke.getCalls().length).to.equal 1
            done()
          , 0
        , 0

    describe 'getLatestChange', ->
      it 'should return the pattern with the latest mtime', ->
        fileList = getFileList()
        expect(bridge.getLatestChange fileList).to.deep.equal fileList.foo[2]

    describe 'updateStats', ->

      beforeEach ->
        bridge._resetStats()

      it 'should increment internal counters about tests and environments', ->
        bridge.updateStats success: 3, failed: 2, exitCode: 1
        bridge.updateStats success: 6, failed: 0, exitCode: 0
        bridge.updateStats success: 2, failed: 0, exitCode: 0
        expect(bridge.stats.tests.success).to.equal 11
        expect(bridge.stats.tests.failed).to.equal 2
        expect(bridge.stats.environments.failed).to.equal 1
        expect(bridge.stats.environments.success).to.equal 2

    describe 'printStatInfo', ->
      beforeEach ->
        bridge._resetStats()
        bridge.logger.info = sinon.spy()

      it 'should log something', ->
        bridge.printStatInfo()
        expect(bridge.logger.info).to.have.been.called

    describe 'fireDoneCallbacks', ->
      it 'should execute functions of doneCallbacks', (done) ->
        test = ''
        bridge.doneCallbacks.push -> test += 'foo'
        bridge.fireDoneCallbacks().then ->
          expect(test).to.equal 'foo'
          done()

    describe 'runComplete', ->
      beforeEach ->
        bridge._resetStats()
        bridge.updateStats = sinon.spy()

      it 'should call updateStats', ->
        bridge.runComplete()
        expect(bridge.updateStats).to.have.been.called

      it 'should leave allPassed true if we did not fail', ->
        bridge.runAll()
        bridge.runComplete [], exitCode: 0
        bridge.runComplete [], exitCode: 0
        expect(bridge.allPassed).to.equal true

      it 'should set allPassed to false if we failed once', ->
        bridge.runAll()
        bridge.runComplete [], exitCode: 0
        bridge.runComplete [], exitCode: 1
        bridge.runComplete [], exitCode: 0
        bridge.runComplete [], exitCode: 0
        expect(bridge.allPassed).to.equal false

      it 'should manipulate the exit code of the last run if we failed', ->
        bridge.runAll()
        bridge.runComplete [], exitCode: 1
        results = exitCode: 0
        bridge.lastRun = true
        bridge.runComplete [], results
        expect(results.exitCode).to.equal 1

      it 'should printStatInfo on last run', ->
        bridge.printStatInfo = sinon.spy()
        bridge.lastRun = true
        bridge.runComplete [], exitCode: 0
        expect(bridge.printStatInfo).to.have.been.called

      it 'should not printStatInfo on previous runs', ->
        bridge.printStatInfo = sinon.spy()
        bridge.runComplete()
        expect(bridge.printStatInfo).not.to.have.been.called

      it 'should fire the done callbacks', ->
        bridge.fireDoneCallbacks = sinon.spy()
        bridge.runComplete()
        expect(bridge.fireDoneCallbacks).to.have.been.called

    describe 'fileListModified', ->
      run = (cb) ->
        setTimeout cb, 0

      beforeEach ->
        bridge.watching = true

      it 'should reset last run and watching properties', (done) ->
        bridge.lastRun = true
        bridge.watching = true
        bridge.fileListModified Q.all []
        run ->
          expect(bridge.lastRun).to.equal false
          expect(bridge.watching).to.equal false
          done()

      it 'should execute runEnvironmentsByFile of the controller', (done) ->
        d = Q.defer()
        d.resolve getFileList()
        controller = injector.get 'controller'
        controller.runEnvironmentsByFile = sinon.spy()
        bridge.fileListModified d.promise
        run ->
          expect(controller.runEnvironmentsByFile).to.have.been.calledWith 'foo'
          done()

      it 'should reactivate the watchers after re-run', (done) ->
        bridge.startWatching = sinon.spy()
        bridge.fileListModified Q.all []
        run ->
          expect(bridge.startWatching).to.have.been.called
          done()

    describe 'browserRegister', ->
      launcher = null

      beforeEach ->
        launcher = injector.get 'launcher'

      it 'should mark browsers as captured', ->
        launcher.markCaptured = sinon.spy()
        bridge.browserRegister id: 'foo'
        expect(launcher.markCaptured).to.have.been.calledWith 'foo'

      it 'should runAll when all browsers are captured', ->
        launcher.areAllCaptured = sinon.stub().returns true
        bridge.runAll = sinon.stub().returns Q.all []
        bridge.browserRegister launchId: 'foo'
        expect(bridge.runAll).to.have.been.called
