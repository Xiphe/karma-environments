_                        = require 'lodash'
fs                       = require 'fs'
Q                        = require 'q'
Base                     = require './Base'
path                     = require 'path'
karmaDir                 = path.join process.cwd(), 'node_modules/karma'
core_watcher             = require path.join karmaDir, 'lib/watcher'
core_createPatternObject = require(path.join(karmaDir, 'lib/config')).createPatternObject

###*
 * Handle interactions with Karma
 * Used by EnvironmentRunner and EnvironmentController
###
class KarmaBridge extends Base
  constructor: ->
    super

    ###*
     * List of callbacks to be notified when a run is complete
     * @type {Array}
    ###
    @doneCallbacks = []

    ###*
     * Check if any run has failed.
     * Used to set the return value in runComplete()
     * @type {Boolean}
    ###
    @allPassed = false

    ###*
     * Are we watching right now?
     * Used to disable fileListModified() while running
     * @type {Boolean}
    ###
    @watching = false

    ###*
     * Cache of the files each framework adds to environment
     * Populated in setFrameworks()
     * @type {Object}
    ###
    @frameworkCache = {}

    ###*
     * Statistics of all tests and environments
     * @type {Object}
    ###
    @stats =
      tests:
        success: 0
        failed: 0
      environments:
        success: 0
        failed: 0
        skipped: 0

    ###*
     * A list of all environment files we know
     * Populated in getPatterns()
     * @type {Array}
    ###
    @allFiles = []

    ###*
     * A list of pattern objects for the environment files
     * Needs to be synchronous to allFiles
     * Populated in getPatterns()
     * @type {Array}
    ###
    @allPatternObjects = []

    #* Store original values of configuration parameters we'll manipulate later
    @originalSingleRun = @config.singleRun
    @originalAutoWatch = @config.autoWatch
    @originalConfigFiles = _.clone @config.files


  ###*
   * Initiate the framework by listening on karmas events
   * and reacting to them.
   * @return {void}
  ###
  init: ->
    #* Disable single run and watching for now
    #* Well handle that later in startWatching() and runAll()
    @config.singleRun = false
    @config.autoWatch = false

    #* Hook into karma
    @emitter.on 'run_complete', @runComplete
    @emitter.on 'file_list_modified', @fileListModified
    @emitter.on 'browser_register', @browserRegister

  ###*
   * Apply the frameworks we want to use.
   * Also initiate and cache them.
   * @param {Array} frameworks
  ###
  setFrameworks: (frameworks) =>
    configFiles = @config.files

    for framework in frameworks
      if not @frameworkCache[framework]
        @config.files = []
        @injector.get "framework:#{framework}"
        @frameworkCache[framework] = _.clone @config.files

      configFiles = @frameworkCache[framework].concat configFiles

    @config.files = configFiles

  ###*
   * Create a list of patterns from given paths.
   * Used in runner.run()
   * @param  {Array} files
   * @return {Array}
  ###
  getPatterns: (files) ->
    patterns = []
    for file in files

      #* Check if we already know this file
      index = @allFiles.indexOf file
      if index >= 0
        patterns.push @allPatternObjects[index]

      #* Create object if this file is new
      else
        patternObj = core_createPatternObject file
        patterns.push patternObj
        @allFiles.push file
        @allPatternObjects.push patternObj

    patterns

  ###*
   * Trigger and monitor all environments on the controller.
   * @param  {Boolean} andWatch activate the watcher afterwards
   * @return {Object}           promise
  ###
  runAll: (andWatch = true) =>
    #* Reset monitoring vars
    @allPassed = true
    @lastRun   = false
    @watching  = false

    #* Execute
    @controller.runAll =>
      @lastRun = true
      @config.singleRun = @originalSingleRun
    .then =>
      @startWatching() if andWatch

  ###*
   * (Re)activate watch related events.
   * @return {void}
  ###
  startWatching: ->
    if @originalAutoWatch
      @originalAutoWatch = false
      @config.files = @config.files.concat @allPatternObjects
      @fileList.reload(@config.files, @config.exclude).then =>
        @originalAutoWatch = true
        @watching = true
        @injector.invoke core_watcher.watch
        @logger.info 'Waiting for changes...'

  ###*
   * Search the latest modified file from the list
   * @todo Get this info from watcher
   * @param  {Object} fileList
   * @return {Object}
  ###
  getLatestChange: (fileList) ->
    latestChange = {}
    latestMtime = 0
    for key, state of fileList
      for pattern in state
        mtime = new Date(pattern.mtime).getTime()
        if mtime > latestMtime
          latestMtime = mtime
          latestChange = pattern

    latestChange

  ###*
   * Counting of total tests and environments run.
   * @param  {Object} results
   * @return {void}
  ###
  updateStats: (results) ->
    @stats.tests.success += results.success
    @stats.tests.failed += results.failed

    if results.exitCode == 0
      @stats.environments.success++
    else
      @stats.environments.failed++

  ###*
   * Print infos about total tests and environments run.
   * @return {void}
  ###
  printStatInfo: ->
    if not @originalAutoWatch
      testsCount = @stats.tests.success + @stats.tests.failed
      environmentCount = @stats.environments.success + @stats.environments.failed
      totalEnvironments = @controller.getEnvironmentsWithTests().length

      tests = "#{testsCount} Tests (#{@stats.tests.success} SUCCESS | " +
        "#{@stats.tests.failed} FAILED)"

      environments = "#{environmentCount} Environments " +
        "(#{@stats.environments.success} SUCCESS | #{@stats.environments.failed} FAILED"
      if totalEnvironments > environmentCount
        environments += " | #{totalEnvironments - environmentCount} SKIPPED"
      environments += ')'

      @logger.info "Total: #{tests} in #{environments}"

  ###*
   * See function name
   * @return {void}
  ###
  fireDoneCallbacks: ->
    @_runQueue @doneCallbacks

  ###*
   * An environment has finished now:
   *   - gather data
   *   - manage exit code
   *   - notify when we're done
   *   - execute callbacks
   * @param  {Object} browsers
   * @param  {Object} results
   * @return {void}
  ###
  runComplete: (browsers, results) =>
    if not @originalAutoWatch
      @updateStats results

    @allPassed = false if !results or !@allPassed or results.exitCode != 0

    if @lastRun
      results.exitCode = if @allPassed then 0 else 1
      @printStatInfo()

    @fireDoneCallbacks()


  ###*
   * Re-execute environments when were watching and a file has been updated.
   * @param  {Object} filesPromise
   * @return {void}
  ###
  fileListModified: (filesPromise) =>
    if @watching
      filesPromise.then (files) =>
        @lastRun = false
        @watching = false
        @controller.runEnvironmentsByFile(@getLatestChange(files).originalPath).then =>
          @startWatching()

  ###*
   * Mark new browsers as captured and run environments when we got em all.
   * @param  {Object} browser
   * @return {void}
  ###
  browserRegister: (browser) =>
    #* Got to mark it as captured before we can check allCaptured.
    if browser.launchId
      @launcher.markCaptured browser.launchId

    #* This will be the first set to kick off the tests.
    if @launcher.areAllCaptured()
      @runAll().catch (error) =>
        @logger.error error.toString() || error
        @launcher.kill ->
          process.exit(1)


KarmaBridge.$inject = Base.$inject.concat ['controller', 'emitter', 'injector', 'launcher', 'fileList']
module.exports = KarmaBridge
