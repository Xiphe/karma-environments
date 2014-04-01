describe 'karma environment', ->
  Q                = require 'q'
  di               = require 'di'
  proxyquire       = require 'proxyquire'

  envDefStub       = sinon.spy()
  fsStub           = {}
  tempStub         = track: -> return tempStub
  KarmaEnvironment = proxyquire.noCallThru() lib('KarmaEnvironment'),
    envDefinition: envDefStub
    fs: fsStub
    temp: tempStub

  it 'should exist', ->
    expect(KarmaEnvironment).to.exist

  describe 'KarmaEnvironment', ->
    karmaEnv = null
    injector = null

    beforeEach ->
      injector = new di.Injector [
        logger: ['type', require fake 'Logger']
        runner: ['type', require fake 'Runner']
        config: ['value', require fake 'config']
        constants: ['value', require lib 'constants']
      ]
      karmaEnv = injector.instantiate KarmaEnvironment

    it 'should have an instance', ->
      expect(karmaEnv).to.exist

    describe 'initWithDefinition', ->
      fakeDefFile = '/lorem/ipsum/dolor/sit/amet.js';

      beforeEach ->
        karmaEnv._load = sinon.spy()
        karmaEnv.initWithDefinition(fakeDefFile)

      it 'should generate from path', ->
        expect(karmaEnv._name).to.equal 'Dolor Sit'

      it 'should set basePath and definitionFile', ->
        expect(karmaEnv._definitionFile).to.equal fakeDefFile
        expect(karmaEnv._basePath).to.equal '/lorem/ipsum/dolor/sit'

      it 'should call _load', ->
        expect(karmaEnv._load).to.have.been.called

    describe 'getters', ->
      it 'should have a hasFocus getter', ->
        karmaEnv._focus = 'abc'
        expect(karmaEnv.hasFocus()).to.equal 'abc'

      it 'should have a test length getter', ->
        karmaEnv._tests = ['a', 'b', 'c']
        expect(karmaEnv.getAmountOfTests()).to.equal 3

      it 'should have a isActive getter', ->
        karmaEnv._active = 'def'
        expect(karmaEnv.isActive()).to.equal 'def'

      it 'should have a frameworks getter', ->
        karmaEnv._frameworks = ['a']
        expect(karmaEnv.getFrameworks()).to.deep.equal ['a']

      it 'should have an environment getter', ->
        karmaEnv._environment = ['b', 'c']
        expect(karmaEnv.getEnvironment()).to.deep.equal ['b', 'c']

    describe 'run', ->
      runner = null

      beforeEach ->
        runner = injector.get 'runner'
        runner.run = sinon.spy()

      it 'should call the run method of runner', ->
        karmaEnv.run()
        expect(runner.run).to.have.been.called

      it 'should not call the runner if deactivated', ->
        karmaEnv._active = false
        karmaEnv.run()
        expect(runner.run).not.to.have.been.called

      it 'should pass frameworks to the runner', ->
        karmaEnv._frameworks = ['lorem']
        karmaEnv.run()
        expect(runner.run.getCall(0).args[0]).to.deep.equal ['lorem']

      it 'should pass environment and tests to the runner', ->
        karmaEnv._environment = ['ipsum.js']
        karmaEnv._tests = ['dolorSpec.js']
        karmaEnv.run()
        expect(runner.run.getCall(0).args[1]).to.deep.equal ['ipsum.js', 'dolorSpec.js']

      it 'should pass a done callback to the runner', ->
        karmaEnv.run()
        expect(runner.run.getCall(0).args[2]).to.be.instanceof Function

    describe 'hasFile', ->
      it 'should return false if file is not present in tests and env', ->
        expect(karmaEnv.hasFile 'foo.js').to.equal false

      it 'should return true if file is present in tests', ->
        karmaEnv._tests = ['foo.js']
        expect(karmaEnv.hasFile 'foo.js').to.equal true

      it 'should return true if file is present in tests', ->
        karmaEnv._environment = ['foo.js']
        expect(karmaEnv.hasFile 'foo.js').to.equal true

    describe 'addParent', ->
      it 'should add parent', ->
        parent = 'a'
        karmaEnv.addParent parent
        expect(karmaEnv._parent).to.equal parent

    describe 'isParentOf', ->
      it 'should recognize its childs', ->
        karmaEnv._basePath = '/foo'
        expect(karmaEnv.isParentOf '/foo/bar/.karma.env.js').to.equal true

      it 'should return false for non childs', ->
        karmaEnv._basePath = '/foo'
        expect(karmaEnv.isParentOf '/bar/.karma.env.js').to.equal false

      it 'should not be its own parent', ->
        definition = '/foo/.karma.env.js'
        karmaEnv._definitionFile = definition
        karmaEnv._basePath = '/foo'
        expect(karmaEnv.isParentOf definition).to.equal false

    describe 'ready', ->
      it 'should return a promise', ->
        expect(karmaEnv.ready().then).to.be.instanceof Function

      it 'it should execute a callback when ready', (done) ->
        karmaEnv.ready done
        karmaEnv._call = sinon.spy()
        karmaEnv._searchTests = sinon.spy()
        karmaEnv._load()

    describe '_ucfirst', ->
      it 'should capitalize the first letter of a string', ->
        expect(karmaEnv._ucfirst 'foo bar').to.equal 'Foo bar'

    describe '_load', ->
      beforeEach ->
        karmaEnv._call = sinon.stub().returns Q.all []
        karmaEnv._searchTests = sinon.stub().returns Q.all []
        karmaEnv._definitionFile = 'envDefinition'

      it 'should require the definition file and pass its function to call', (done) ->
        karmaEnv._load().then ->
          expect(karmaEnv._call).to.have.been.calledWith envDefStub, karmaEnv._name
          done()

      it 'should call search Tests before resolving its promise', (done) ->
        karmaEnv._load().then ->
          expect(karmaEnv._searchTests).to.have.been.called
          done()

      it 'should call _call', (done) ->
        karmaEnv._load().then ->
          expect(karmaEnv._call).to.have.been.called
          done()

      it "should resolve it's ready deferred", (done) ->
        karmaEnv._readyDeferred.promise.then -> done()
        karmaEnv._load()

    describe '_searchTests', ->
      it 'should disable itself if we do not search tests', ->
        karmaEnv.dslNotests()
        karmaEnv._searchTests()
        expect(karmaEnv.isActive()).to.equal false

      setReaddir = (files) ->
        fsStub.readdir = (dir, callback) ->
          newFiles = []
          files.forEach (path) ->
            file = path.replace(dir, '')
            if file.indexOf('/') > 0
              newFiles.push "#{file.split('/')[0]}/"
            else if path.indexOf(dir) >= 0
              newFiles.push file

          callback false, newFiles

      beforeEach ->
        fsStub.lstat = (path, callback) ->
          callback(false, isDirectory: -> path.charAt(path.length - 1) == '/')

      it 'should add some tests',  ->
        files = ['fooSpec.js', 'barSpec.coffee']
        setReaddir files
        karmaEnv._searchTests()
        expect(karmaEnv._tests).to.deep.equal(files)

      it 'should not add files that are not matching the test matcher', ->
        setReaddir ['loremSpec.js', '.DS_Store']
        karmaEnv._searchTests()
        expect(karmaEnv._tests).to.deep.equal(['loremSpec.js'])

      it 'should also get files from subdirectories', ->
        files = ['fooSpec.js', 'lorem/barSpec.coffee']
        setReaddir files
        karmaEnv._searchTests()
        expect(karmaEnv._tests).to.deep.equal(files)

      it 'should stop searching in subdirectories if a new definition is present', ->
        setReaddir ['fooSpec.js', 'lorem/barSpec.coffee', 'lorem/foobar']
        karmaEnv._searchTests()
        expect(karmaEnv._tests).to.deep.equal(['fooSpec.js'])

      it 'should not stop searching if the definition is in root dir', ->
        setReaddir ['fooSpec.js', 'lorem/barSpec.coffee', 'foobar']
        karmaEnv._searchTests()
        expect(karmaEnv._tests).to.deep.equal(['fooSpec.js', 'lorem/barSpec.coffee'])

      it 'should fail if readdir has an error', (done) ->
        fsStub.readdir = (dir, callback) ->
          callback 'some error'

        karmaEnv._searchTests().catch (error) ->
          expect(error.message).to.equal 'some error'
          done()

      it 'should fail if lstat has an error', (done) ->
        setReaddir ['foo']
        fsStub.lstat = (dir, callback) ->
          callback 'some other error'

        karmaEnv._searchTests().catch (error) ->
          expect(error.message).to.equal 'some other error'
          done()

    describe '_prepareSnippet', ->
      beforeEach ->
        tempStub.open = sinon.stub().callsArgWith(1, false, fd: 3, path: '/tmp/knkrtzx.js')
        fsStub.write = sinon.stub().callsArgWith(4, false)
        fsStub.close = (fd, callback) -> callback()

      it 'should create a temp file', ->
        karmaEnv._prepareSnippet ->
        expect(tempStub.open).to.have.been.called

      it 'should write to a temp file', ->
        karmaEnv._prepareSnippet ->
        expect(fsStub.write).to.have.been.called

      it 'should use the tempfile we got from temp.open', ->
        karmaEnv._prepareSnippet ->
        expect(fsStub.write.getCall(0).args[0]).to.equal 3

      it 'should write our callback into the temp file', (done) ->
        callback = (jQuery) ->
          jQuery.foo()

        expectation = "(function (jQuery) { return jQuery.foo(); })(jQuery);"

        karmaEnv._prepareSnippet callback, ->
          expect(fsStub.write.getCall(0).args[1].replace(/[\s]+/g, ' ')).to.equal expectation
          done()

      it 'should push the temp file to the environment list', ->
        karmaEnv._prepareSnippet ->
        expect(karmaEnv._environment[0]).to.equal '/tmp/knkrtzx.js'

      it 'should reject on error', ->
        fsStub.close = (fd, callback) -> callback 'fu'
        cb = ->
        done = ->
        fail = sinon.spy()
        karmaEnv._prepareSnippet cb, done, fail
        expect(fail).to.have.been.called
        expect(fail.getCall(0).args[0].message).to.equal 'fu'

    describe '_inherit', ->
      parent = null

      beforeEach ->
        parent = injector.instantiate KarmaEnvironment
        parent._readyDeferred.resolve()
        karmaEnv._parent = parent

      it 'should wait for parent environment to be ready', ->
        parent.ready = sinon.spy()
        karmaEnv._inherit()
        expect(parent.ready).to.have.been.called

      it 'should quick return if no parent is present', ->
        karmaEnv._parent = false
        expect(karmaEnv._inherit()).not.to.exists

      it 'should copy frameworks of parent', (done) ->
        parent._frameworks = ['lorem']
        karmaEnv._inherit().then ->
          expect(karmaEnv._frameworks).to.deep.equal ['lorem']
          done()

      it 'should copy environment of parent', (done) ->
        parent._environment = ['ipsum']
        karmaEnv._inherit().then ->
          expect(karmaEnv._environment).to.deep.equal ['ipsum']
          done()

      it 'should create a new copy of frameworks', (done) ->
        parent._frameworks = ['lorem']
        karmaEnv._inherit().then ->
          karmaEnv._frameworks.push('ipsum')
          expect(karmaEnv._frameworks.length).to.equal 2
          expect(parent._frameworks.length).to.equal 1
          done()

      it 'should create a new copy of environment', (done) ->
        parent._environment = ['ipsum']
        karmaEnv._inherit().then ->
          karmaEnv._environment.push('dolor')
          expect(karmaEnv._environment.length).to.equal 2
          expect(parent._environment.length).to.equal 1
          done()


    describe '_addFile', ->
      beforeEach ->
        karmaEnv._getFirstExistant = sinon.stub().returns Q.all []

      it 'should pass possible paths of the file to _getFirstExistant', ->
        karmaEnv._basePath = 'foo'
        karmaEnv._addFile 'bar.js'
        expect(karmaEnv._getFirstExistant).to.have.been.calledWith ['foo/bar.js', 'bar.js']

      it 'should add prefix variants if required', ->
        karmaEnv._basePath = 'foo'
        karmaEnv._addFile 'bar.js', 'fara'
        expect(karmaEnv._getFirstExistant).to.have.been.calledWith ['foo/fara/bar.js', 'foo/bar.js', 'fara/bar.js', 'bar.js']

    describe '_getFirstExistant', ->
      beforeEach ->
        fsStub.exists = sinon.stub().callsArgWith(1, false)

      it 'should call fs.exist for all files', ->
        karmaEnv._getFirstExistant ['a', 'b', 'c']
        expect(fsStub.exists.getCall(0).args[0]).to.equal 'a'
        expect(fsStub.exists.getCall(1).args[0]).to.equal 'b'
        expect(fsStub.exists.getCall(2).args[0]).to.equal 'c'

      it 'should reject if none of the files exist', (done) ->
        karmaEnv._getFirstExistant(['foo/bar.js']).catch (error) ->
          expect(error.message).to.equal 'Unable to find file bar.js, looked here foo/bar.js'
          done()

      it 'should resolve if the file exists', (done) ->
        fsStub.exists.callsArgWith(1, true)
        karmaEnv._getFirstExistant(['a']).then (file) ->
          expect(file).to.equal 'a'
          done()

    describe '_call', ->
      it 'should fail if we do not pass a function', (done) ->
        karmaEnv._call('foo', 'bar').catch (error) ->
          expect(error.message).to.equal "'bar' needs to export a function. Got String"
          done()

      it 'should fail if we pass a function without args', (done) ->
        func = ->
        karmaEnv._call(func, 'foo').catch (error) ->
          expect(error.message).to.equal "Executing 'foo' without arguments, why u no like 'environment'?"
          done()

      it 'should call our function with injections from _prepareCallInjections', ->
        karmaEnv._prepareCallInjections = sinon.stub().returns foo: ['value', 'bar']
        fixture = ''
        func = (foo) ->
          fixture = foo
        karmaEnv._call func
        expect(fixture).to.equal 'bar'


    describe '_prepareCallInjections', ->
      d = null
      beforeEach ->
        d = Q.defer()

      it 'should return false if "environment" is not present in arguments',  ->
        expect(karmaEnv._prepareCallInjections([], d, 'foo')).to.equal false

      it 'should reject if "environment" is not present in arguments', (done) ->
        retVal = karmaEnv._prepareCallInjections([], d, 'foo')
        d.promise.catch (error) ->
          expect(error.message).to.equal "Missing environment parameter for call in 'foo'"
          done()

      it 'should call _newDsl for new environments', ->
        karmaEnv._newDsl = sinon.spy()
        karmaEnv._prepareCallInjections(['environment'], d, 'foo')
        expect(karmaEnv._newDsl).to.have.been.called

      it 'should return a injectable object', ->
        karmaEnv._newDsl = -> 'dsl'
        injections = karmaEnv._prepareCallInjections(['environment'], d, 'foo')
        expect(injections).to.be.instanceof Object
        expect(injections.environment).to.deep.equal ['value', 'dsl']

      it 'should add a done callback to injections', ->
        injections = karmaEnv._prepareCallInjections(['environment'], d, 'foo')
        expect(injections.done[1]).to.be.instanceof Function

      it 'should add a error callback to injections', ->
        injections = karmaEnv._prepareCallInjections(['environment'], d, 'foo')
        expect(injections.error[1]).to.be.instanceof Function

      it 'should run the queue automatically if we no not require done as a dependency', (done) ->
        karmaEnv._prepareCallInjections(['environment'], d, 'foo')
        d.promise.then done

      it 'should run the queue when we call done', (done) ->
        injections = karmaEnv._prepareCallInjections(['environment', 'done'], d, 'foo')
        injections.done[1]()
        d.promise.then done

      it 'should reject if we call error', (done) ->
        injections = karmaEnv._prepareCallInjections(['environment', 'done'], d, 'foo')
        injections.error[1]('something went wrong')
        d.promise.catch (error) ->
          expect(error).to.equal 'something went wrong'
          done()

      it 'should reject if we do not call done within timeout', (done) ->
        karmaEnv._prepareCallInjections(['environment', 'done'], d, 'foo')
        d.promise.catch (error) ->
          expect(error.message).to.equal "Timed out while waiting for done() to be called in 'foo'"
          done()

    describe '_getPathHelper', ->
      helper = null

      beforeEach ->
        karmaEnv._basePath = '/envPath'
        helper = karmaEnv._getPathHelper()

      it 'should be a function', ->
        expect(helper).to.be.instanceof Function

      it 'should return the DEFAULT_PATH', ->
        expect(helper()).to.equal '/envPath'

      it 'should be able to add a subpath to DEFAULT_PATH', ->
        expect(helper('my/dir')).to.equal '/envPath/my/dir'

      it 'should be usable as a string', ->
        expect("cwd is #{helper}").to.equal "cwd is /envPath"

      it 'should have a root method', ->
        expect(helper.root()).to.equal '/'

      it 'should have a root method that is usable as a string', ->
        expect("root is #{helper.root}").to.equal "root is /"

      it 'should have a root method that is able to add a subpath to root', ->
        expect(helper.root('my/dir')).to.equal '/my/dir'

      describe 'custom path helpers', ->
        beforeEach ->
          karmaEnv._pathHelper = null
          injector.get('config').environments.customPaths =
            foo: '/bar/baz'
          helper = karmaEnv._getPathHelper()

        it 'should have a foo method', ->
          expect(helper.foo).to.be.instanceof Function

        it 'should return the defined path', ->
          expect(helper.foo()).to.equal '/bar/baz'

        it 'should be able to add a subpath to defined path', ->
          expect(helper.foo('lorem.js')).to.equal '/bar/baz/lorem.js'

        it 'should be usable as a string', ->
          expect("foo is #{helper.foo}").to.equal 'foo is /bar/baz'

    describe 'DSL', ->
      dsl = null
      queue = null

      beforeEach ->
        queue = []
        dsl = karmaEnv._newDsl(queue)

      run = (done) ->
        karmaEnv._runQueue(queue).then done

      describe '_newDsl', ->
        it 'should return an object', ->
          expect(dsl).to.be.instanceof Object
          expect(dsl).not.to.be.instanceof Function

        it 'should not return itself', ->
          expect(dsl).not.to.deep.equal karmaEnv

        it 'should have methods', ->
          expect(dsl.name).to.be.instanceof Function

        it 'should push methods to our queue instead of calling them directly', ->
          karmaEnv.dslName = sinon.spy()
          dsl.name('foo')
          expect(karmaEnv.dslName).not.to.have.been.called
          expect(queue.length).to.equal 1

        it 'should proxy methods to main dsl methods', (done) ->
          karmaEnv.dslName = sinon.spy()
          dsl.name('foo')
          run ->
            expect(karmaEnv.dslName).to.have.been.calledWith 'foo'
            done()

        it 'should make all dsl methods chainable', ->
          karmaEnv.dslName = -> 'something else'
          expect(dsl.name()).to.deep.equal dsl

        it 'should not have access to instance variables', ->
          expect(dsl._tests).not.to.exist

        describe 'custom methods', ->
          custom = null
          customMethods = null
          queue = null
          dsl = null
          test = null

          beforeEach ->
            queue = []
            test = ''

            customMethods =
              foo: (environment) ->
                test += 'foo'

            injector.get('config').environments.customMethods = customMethods
            dsl = karmaEnv._newDsl(queue)
            custom = dsl.foo

          it 'should add custom methods to dsl', ->
            expect(custom).to.be.instanceof Function

          it 'should return the dsl', ->
            expect(custom()).to.deep.equal dsl

          it 'should add a callback to the queue', ->
            expect(queue.length).to.equal 0
            custom()
            expect(queue[0]).to.be.instanceof Function

          it 'should execute the custom method', (done) ->
            custom()
            karmaEnv._runQueue(queue).then ->
              expect(test).to.equal 'foo'
              done()

          it 'should use _call to execute custom methods', (done) ->
            karmaEnv._call = sinon.spy()
            custom()
            karmaEnv._runQueue(queue).then ->
              expect(karmaEnv._call).to.have.been.called
              done()

          it 'should dependency inject arguments', (done) ->
            testArgs = null
            customMethods.bar = (args, environment) ->
              testArgs = args

            karmaEnv._newDsl(queue).bar('lorem')
            karmaEnv._runQueue(queue).then ->
              expect(testArgs[0]).to.equal 'lorem'
              done()

      describe 'clean', ->
        it 'should reset frameworks and environment', (done) ->
          karmaEnv._frameworks = ['asdf']
          karmaEnv._environment = ['foobar.js']
          dsl.clean()
          run ->
            expect(karmaEnv._frameworks.length).to.equal 0
            expect(karmaEnv._environment.length).to.equal 0
            done()

      describe 'name', ->
        it 'should set the name', (done) ->
          dsl.name 'Esmiralda'
          run ->
            expect(karmaEnv._name).to.equal 'Esmiralda'
            done()

      describe 'notests', ->
        it 'should reset tests and disable searching', (done) ->
          karmaEnv._tests = ['baz.js']
          dsl.notests()
          run ->
            expect(karmaEnv._tests.length).to.equal 0
            expect(karmaEnv._dontSearchTests).to.equal true
            done()

      describe 'focus', ->
        it 'should set the focus', (done) ->
          dsl.focus()
          run ->
            expect(karmaEnv._focus).to.equal true
            done()

      describe 'toggle', ->
        it 'should invert activity', (done) ->
          expect(karmaEnv._active).to.equal true
          dsl.toggle()
          run ->
            expect(karmaEnv._active).to.equal false
            done()

        it 'should invert activity', (done) ->
          expect(karmaEnv._active).to.equal true
          dsl.toggle().toggle()
          run ->
            expect(karmaEnv._active).to.equal true
            done()

        it 'should stay true if truthy value is passed', (done) ->
          expect(karmaEnv._active).to.equal true
          dsl.toggle 'asd'
          run ->
            expect(karmaEnv._active).to.equal true
            done()

        it 'should get false if falsy value is passed', (done) ->
          expect(karmaEnv._active).to.equal true
          dsl.toggle 0
          run ->
            expect(karmaEnv._active).to.equal false
            done()

      describe 'activate', ->
        it 'should activate the environment', (done) ->
          karmaEnv._active = false
          dsl.activate()
          run ->
            expect(karmaEnv._active).to.equal true
            done()

      describe 'disable', ->
        it 'should deactivate the environment', (done) ->
          dsl.disable()
          run ->
            expect(karmaEnv._active).to.equal false
            done()

      describe 'add', ->
        beforeEach ->
          karmaEnv._addFile = (file, prefix, done) ->
            karmaEnv._environment.push (file)
            done()

        it 'should add a file to the environment', (done) ->
          dsl.add 'foo.js'
          run ->
            expect(karmaEnv._environment).to.deep.equal ['foo.js']
            done()

        it 'should add multiple files', (done) ->
          files = ['foo.js', 'bar.js']
          dsl.add files
          run ->
            expect(karmaEnv._environment).to.deep.equal files
            done()

        it 'should call _prepareSnippet if we add a function', (done) ->
          karmaEnv._prepareSnippet = (snippet, resolve) ->
            @_environment.push '/tmp/foo.js'
            resolve()

          dsl.add -> 'foo'
          run ->
            expect(karmaEnv._environment).to.deep.equal ['/tmp/foo.js']
            done()

        it 'should keep the order of libs added', (done) ->
          karmaEnv._prepareSnippet = (snippet, resolve) ->
            @_environment.push '/tmp/foo.js'
            resolve()

          snippet = -> 'foo'
          dsl.add ['some.js', snippet, 'other.js']
          run ->
            expect(karmaEnv._environment).to.deep.equal ['some.js', '/tmp/foo.js', 'other.js']
            done()

      describe 'use', ->
        it 'should add a framework', (done) ->
          dsl.use 'my framework'
          run ->
            expect(karmaEnv._frameworks).to.deep.equal ['my framework']
            done()

        it 'should add multiple frameworks', (done) ->
          frameworks = ['my framework', 'my other framework']
          dsl.use frameworks
          run ->
            expect(karmaEnv._frameworks).to.deep.equal frameworks
            done()

      describe 'call', ->
        beforeEach ->
          karmaEnv._call = sinon.spy()

        it 'should initiate a sub call on _call', (done) ->
          dsl.call ->
          run ->
            expect(karmaEnv._call).to.have.been.called
            done()

        it 'should not initiate a sub call if we passed no function', (done) ->
          dsl.call 'foo'
          run ->
            expect(karmaEnv._call).not.to.have.been.called
            done()

        it 'should pass the function to _call', (done) ->
          func = ->
          dsl.call func
          run ->
            expect(karmaEnv._call.getCall(0).args[0]).to.equal func
            done()

        it 'should add numbers to the name', (done) ->
          karmaEnv._name = 'foo'
          dsl.call ->
          dsl.call ->
          run ->
            expect(karmaEnv._call.getCall(0).args[1]).to.equal 'foo:call#0'
            expect(karmaEnv._call.getCall(1).args[1]).to.equal 'foo:call#1'
            done()
