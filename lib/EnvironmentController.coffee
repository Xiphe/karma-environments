KarmaEnvironment = require './KarmaEnvironment'
Base             = require './Base'
glob             = require 'glob'
path             = require 'path'
Q                = require 'q'

###*
 * The caretaker for all our environments
###
class EnvironmentController extends Base
  ###*
   * Initiate instance variables
  ###
  constructor: ->
    super

    ###*
     * All environment instances
     * @type {Array}
    ###
    @environments = []

    ###*
     * All Files that create new environment instances.
     * @type {Array}
    ###
    @environmentDefinitions = []

    ###*
     * Internal flag to prevent double initiation of environments.
     * @type {Boolean}
    ###
    @_setupTriggered = false

    ###*
     * The deferred object handling setup callbacks.
     * @type {Object}
    ###
    @_setupDeferred = Q.defer()

    ###*
     * Promise object, gets resolved once setup is done.
     * @type {Object}
    ###
    @setupPromise = @_setupDeferred.promise

  ###*
   * Find, sort and initiate all environments
   * @return {Object} promise
  ###
  setupEnvironments: ->
    return @setupPromise if @_setupTriggered

    @_setupTriggered = true

    queue = [
      @findEnvironmentDefinitions
      @sortDefinitions
      @initEnvironments
      @handleFocus
      => @logger.debug 'setup done.'
    ]
    @_runQueue queue, @_setupDeferred

    @setupPromise

  ###*
   * Find all environment definitions.
   * @see this.environmentDefinitions
   * @return {Function} promise
  ###
  findEnvironmentDefinitions: =>
    promises = []

    @getDefinitionMatchers().forEach (matcher) =>
      d = Q.defer()
      promises.push d.promise
      glob matcher, cwd: @config.basePath, (error, files) =>
        if error
          d.reject new Error(error)
        else
          for file in files
            @environmentDefinitions.push path.join @config.basePath, file
          d.resolve()

    Q.all promises

  ###*
   * Return definition matchers from config
   * @return {Array}
  ###
  getDefinitionMatchers: ->
    @config.environments.definitions

  ###*
   * Sort the environments, so lower environments will be executed earlier.
   * @return {Array}
  ###
  sortDefinitions: =>
    @environmentDefinitions.sort (a, b) ->
      a.length - b.length

  ###*
   * Create the environment instances
   * @return {Array}
  ###
  initEnvironments: =>
    initiationPromises = []
    for definition in @environmentDefinitions
      environment = @injector.instantiate KarmaEnvironment
      environment.addParent @getParentOf definition
      environment.setAddChild @addEnvironment
      initiationPromises.push environment.initWithDefinition definition
      @addEnvironment environment

    Q.all initiationPromises

  ###*
   * Add a new environment to the list of all environments
   * Used for Child/Header environments
   * @param {Object} environment
  ###
  addEnvironment: (environment) =>
    @environments.push environment

  ###*
   * Get parent environment of a environment definition
   * @param  {String} definition definition path
   * @return {Object|void}
  ###
  getParentOf: (definition) ->
    filtered = @environments.filter (environment) ->
      environment.isParentOf(definition)

    return if filtered.length then filtered[filtered.length - 1] else false

  ###*
   * Disable unfocused environments if any is focused
   * @return {void}
  ###
  handleFocus: =>
    hasFocus = false
    #* check if any environment has focus
    for environment in @environments
      if environment.hasFocus()
        hasFocus = true
        break

    #* return if no focus found
    return if not hasFocus

    #* disable unfocused if focus found
    for environment in @environments
      if not environment.hasFocus()
        environment.dslDisable()

    null

  ###*
   * Get a list of those environments that have tests.
   * @return {Array}
  ###
  getEnvironmentsWithTests: ->
    environments = []
    for environment in @environments
      if environment.getAmountOfTests()
        environments.push environment

    environments

  ###*
   * Get a list of all active environments
   * @param  {Array|null} environments optional pre-filtered list of environments.
   * @return {Array}
  ###
  getActiveEnvironments: (environments = @environments) ->
    filteredEnvironments = []
    for environment in environments
      if environment.isActive()
        filteredEnvironments.push environment

    filteredEnvironments

  ###*
   * Loop through all present environments and return those who
   * know a given file.
   * @param  {String} file
   * @return {Array}
  ###
  getEnvironmentsByFile: (file) ->
    environments = []
    for environment in @environments
      if environment.hasFile file
        environments.push environment

    environments

  ###*
   * Execute all environments who know a given file
   * @param  {String}   file
   * @param  {Function} beforeLast callback before last run is executed
   * @return {Object}              Promise
  ###
  runEnvironmentsByFile: (file, beforeLast) ->
    @run @getEnvironmentsByFile(file), beforeLast

  ###*
   * Execute all known environments
   * @param  {Function} beforeLast callback before last run is executed
   * @return {Object}              Promise
  ###
  runAll: (beforeLast) ->
    @run @environments, beforeLast

  ###*
   * Run an array of environments
   * @param  {Array}    environments
   * @param  {Function} beforeLast   callback before last run is executed
   * @return {Object}                Promise
  ###
  run: (environments, beforeLast) ->
    d = Q.defer()

    promise = @setupEnvironments()

    promise.then =>
      queue = (environment.run for environment in @getActiveEnvironments(environments))
      if beforeLast instanceof Function
        queue.splice queue.length - 1, 0, beforeLast
      queue.push => @logger.debug 'All environments done.'
      @_runQueue queue, d

    promise.catch d.reject

    d.promise


#* Set the dependencies and export
EnvironmentController.$inject = Base.$inject.concat ['injector']
module.exports = EnvironmentController
