minimatch = require 'minimatch'
Base      = require './Base'
path      = require 'path'
glob      = require 'glob'
temp      = require('temp').track()
fs        = require 'fs'
di        = require 'di'
di_parse  = require('../node_modules/di/lib/annotation').parse
Q         = require 'Q'
_         = require 'lodash'

###*
 * This methods will be exposed into environment definitions.
 * @const
 * @type {Array}
###
DSL_METHODS = [
  'activate'
  'disable'
  'toggle'
  'focus'
  'clean'
  'name'
  'notests'
  'add'
  'use'
  'call'
]

###*
 * KarmaEnvironment Class
###
class KarmaEnvironment extends Base
  ###*
   * Setup instance variables
   * @return {void}
  ###
  constructor: ->
    super

    ###*
     * Active
     * Gets false if other environments are focused
     * Change with DSL Methods:
     *   activate, disable, toggle
     * @type {Boolean}
    ###
    @_active = true

    ###*
     * The Root folder for this definition
     * Set in initWithDefinition
     * @type {String}
    ###
    @_basePath = ''

    ###*
     * How often have we called dslCall
     * @type {Number}
    ###
    @_callCount = 0

    ###*
     * The file defining this environment
     * Set in initWithDefinition
     * @type {String}
    ###
    @_definitionFile = ''

    ###*
     * Just inherit from this one
     * Set with DSL Method:
     *   notests
     * @type {Boolean}
    ###
    @_dontSearchTests = false

    ###*
     * Source files that we want to test.
     * Set with DSL Method:
     *   add
     * @type {Array}
    ###
    @_environment = []

    ###*
     * Deactivate environments without focus if true
     * Set with DSL Method:
     *   focus
     * @type {Boolean}
    ###
    @_focus = false

    ###*
     * List of karma frameworks we want to use in this environment
     * Set with DSL Method:
     *   use
     * @type {Array}
    ###
    @_frameworks = []

    ###*
     * Name of this environment
     * Auto-generated with _generateName()
     * Change with DSL Method:
     *   name
     * @type {String}
    ###
    @_name = ''

    ###*
     * List of parent environments
     * Set in addParents
     * @type {Array}
    ###
    @_parent = false

    ###*
     * All test files
     * Disable by setting _dontSearchTests to true
     * Auto-searched using config.environments.tests
     * @type {Array}
    ###
    @_tests = []

    ###*
     * Ready deferred
     * @type {Object}
    ###
    @_readyDeferred = Q.defer()


  ###*
   * Forget about all frameworks and environment libraries
   * @return {KarmaEnvironment}
  ###
  dslClean: ->
    @_frameworks = []
    @_environment = []

  ###*
   * Set the name for this environment
   * @param  {String} name
   * @return {KarmaEnvironment}
  ###
  dslName: (name) ->
    @_name = name

  ###*
   * Disable Test-file search
   * Use this on low laying environments that only
   * define basic frameworks for sub-folders and
   * don't have own tests.
   * @return {KarmaEnvironment}
  ###
  dslNotests: ->
    @_tests = []
    @_dontSearchTests = true

  ###*
   * Disable all other tests
   * @param  {mixed} EXPRESSION totally unnecessary
   * @return {KarmaEnvironment}
  ###
  dslFocus: ->
    @_focus = true

  ###*
   * Toggle activeness for this environment.
   * Does not bubble to sub-environments.
   * @param  {Boolean} onoff -optional
   * @return {KarmaEnvironment}
  ###
  dslToggle: (onoff = !@_active) ->
    @_active = !!onoff
  #* aliases for toggle
  dslActivate: ->
    @dslToggle true
  dslDisable: ->
    @dslToggle false

  ###*
   * Add one or more libraries to the environment
   * Functions will be closured and put into a temporary file.
   * @param  {String|Array|Function} libs
   * @param  {String}                prefix Some base path to prefix all strings. -optional
   * @return {KarmaEnvironment}
  ###
  dslAdd: (libs, prefix) ->
    if (libs not instanceof Array)
      libs = [libs]

    queue = []
    d = Q.defer()

    libs.forEach (lib, i) =>
      if lib
        queue.push =>
          d = Q.defer()
          if lib instanceof Function
            @_prepareSnippet lib, d.resolve, d.reject
          else
            @_addFile lib, prefix, d.resolve, d.reject
          return d.promise

      if i == libs.length - 1
        @_runQueue queue, d

    d.promise

  ###*
   * Set one or more frameworks to be used by karma
   * @param  {String|Array} frameworks
   * @return {KarmaEnvironment}
  ###
  dslUse: (frameworks = false) ->
    return if not frameworks;

    if (frameworks not instanceof Array)
      frameworks = [frameworks]

    @_frameworks = @_frameworks.concat(frameworks);

  ###*
   * Add a new asynchronous task into the loading queue
   * @param  {Function} callback resolver and rejector gets passed into callback
   * @return {KarmaEnvironment}
  ###
  dslCall: (callback) ->
    #* Quick return
    return if callback not instanceof Function

    return @_call callback, "#{@_name}:call##{@_callCount++}"

  # INTERNAL
  # ========

  ###*
   * Set the definition file and load it.
   * @param  {String} file
   * @return {Function}      Promise
  ###
  initWithDefinition: (file) ->
    @_definitionFile = file
    @_basePath = path.dirname file
    @dslName @_generateName()

    @_load()

  ###*
   * Add a parent environment for later inheritance
   * @param {Object} environment
  ###
  addParent: (environment) ->
    @_parent = environment

  ###*
   * Check if this is a parent of given path
   * @param  {String}  definition
   * @return {Boolean}
  ###
  isParentOf: (definition) ->
    @_definitionFile != definition &&
      definition.indexOf(@_basePath) == 0

  ###*
   * Add a ready callback or get the promise
   * @param  {Function} callback
   * @return {Object}            promise
  ###
  ready: (callback) ->
    if callback instanceof Function
      @_readyDeferred.promise.then callback

    @_readyDeferred.promise

  ###*
   * Check if this environment has focus
   * @return {Boolean}
  ###
  hasFocus: ->
    @_focus

  ###*
   * Get the amount of tests
   * @return {Number}
  ###
  getAmountOfTests: ->
    @_tests.length

  ###*
   * Get used Frameworks
   * @return {Array}
  ###
  getFrameworks: ->
    @_frameworks

  ###*
   * Get the environment
   * @return {Array}
  ###
  getEnvironment: ->
    @_environment

  ###*
   * Check if this environment is active
   * @return {Boolean}
  ###
  isActive: ->
    @_active

  ###*
   * Execute yourself
   * @return {Object} promise object.
  ###
  run: =>
    return false if not @_active

    d = Q.defer()
    @logger.info "Running \"#{@_name}\"."
    @runner.run @_frameworks, @_environment.concat(@_tests), d.resolve
    d.promise

  ###*
   * Check if this environment has a given file
   * @param  {String}  file
   * @return {Boolean}
  ###
  hasFile: (file) ->
    file in @_tests or file in @_environment


  # "PRIVATE"
  # =========

  ###*
   * Create a name for this environment using the relative
   * path of the folder we found this file in.
   * @return {String}
  ###
  _generateName: () ->
    dirname = path.dirname @_definitionFile.replace @config.basePath, ''

    dirname.split('/').map (token) =>
      token = @_ucfirst token.toLowerCase()
    .join(' ').replace /^\s+|\s+$/g, ''

  ###*
   * Wrap a callback function into a self executing closure
   * Put that thing into a temp file that can be used by karma.
   * @param  {Function} func
   * @return {String}
  ###
  _prepareSnippet: (func, done, error) ->
    args = "#{func}".match(/\(([^\)]*)\)/)[0]

    file = temp.open suffix: '.js', (err, info) =>
      fs.write info.fd, "(#{func})#{args};", undefined, undefined, (err) =>
        if err
          error new Error(err)
          return

        fs.close info.fd, (err) =>
          if err
            error new Error(err)
            return

          @_environment.push info.path
          done?()

  ###*
   * Build expected locations for a file and
   * try to add them to the environment.
   * @param  {string}   file
   * @param  {string}   prefix can be empty for no prefix
   * @param  {Function} done
   * @param  {Function} error
   * @return {void}
  ###
  _addFile: (file, prefix, done, error) ->
    validPrefix = typeof prefix == 'string' and prefix.length
    variants = []
    if validPrefix
      variants.push path.join @_basePath, prefix, file
    variants.push path.join @_basePath, file
    if validPrefix
      variants.push path.join prefix, file
    variants.push file

    @_getFirstExistant(variants).catch(error).then (file) =>
      @_environment.push file
      done()

  ###*
   * Check if a file exist in a list of potential files
   * and resolve the promise with the first one thats existent.
   * @return {Object} promise
  ###
  _getFirstExistant: (files, i = 0, d = Q.defer()) ->
    fs.exists files[i], (exists) =>
      if exists
        d.resolve files[i]
      else
        if i < files.length - 1
          @_getFirstExistant files, ++i, d
        else
          d.reject new Error "Unable to find file #{path.basename files[0]}, looked here #{files}"

    d.promise

  ###*
   * Execute a call on the passed function
   * injecting environment, done and error as potential
   * dependencies
   * @param  {Function} funct
   * @param  {String}   name
   * @param  {Object}   additional optional additional arguments for injection
   * @return {Object}              promise
  ###
  _call: (funct, name, additional = {}) ->
    d = Q.defer()

    if funct not instanceof Function
      d.reject new Error "'#{name}' needs to export a function. Got #{@_ucfirst typeof funct}"
      return d.promise

    args = di_parse funct

    if !args.length
      d.reject new Error "Executing '#{name}' without arguments, why u no like 'environment'?"
    else
      #* Ok, we have arguments prepare dependency injection
      injections = @_prepareCallInjections args, d, name, additional
      if injections
        injector = new di.Injector [injections]
        injector.invoke funct

    return d.promise

  ###*
   * Validate arguments and build an object we can inject into the call
   * @param  {Array}  args       the arguments of the call
   * @param  {Object} d          deferred object, we can reject on
   * @param  {String} name       the name of the call
   * @param  {Object} additional optional additional arguments for injection
   * @return {Object|Boolean}    injection object or false on error
  ###
  _prepareCallInjections: (args, d, name, additional = {}) ->
    queue = []
    async = 'done' in args

    error = (error) =>
      queue = []
      d.reject error
      false

    done = =>
      clearTimeout timeout
      @_runQueue queue, d

    if 'environment' not in args
      return error new Error "Missing environment parameter for call in '#{name}'"

    if not async
      setTimeout done, 10

    timeout = setTimeout =>
      error new Error "Timed out while waiting for done() to be called in '#{name}'"
    , @config.environments.asyncTimeout

    return _.extend additional,
      environment: ['value', @_newDsl(queue)]
      error: ['value', error]
      done: ['value', done]

  ###*
   * Wait for parent environment to be ready and
   * copy used frameworks and environment
   * @return {void}
  ###
  _inherit: =>
    return if !@_parent

    @_parent.ready =>
      @_frameworks = @_parent.getFrameworks()
      @_environment = @_parent.getEnvironment()

  ###*
   * Create a new instance of our DSL object casting on a new queue
   * @param  {Array} queue definition steps go here
   * @return {Object}      DSL instance
  ###
  _newDsl: (queue) ->
    dsl = {}

    DSL_METHODS.forEach (method) =>
      dsl[method] = =>
        args = arguments
        queue.push =>
          @["dsl#{@_ucfirst(method)}"].apply @, args
        dsl

    #* Check for custom methods and append them
    if typeof @config.environments.customMethods == 'object'
      _.each @config.environments.customMethods, (method, name) =>
        subI = 0
        dsl[name] = =>
          args = arguments
          queue.push =>
            @_call method, "#{@_name}:#{name}##{subI++}", args: ['value', args]
          dsl

    dsl

  ###*
   * Capitalize the first letter of a string
   * @param  {String} str
   * @return {String}
  ###
  _ucfirst: (str) ->
    "#{str.charAt(0).toUpperCase()}#{str.slice(1)}"

  ###*
   * Require and Call an environment configuration file.
   * @return {void}
  ###
  _load: ->
    @_runQueue [
      @_inherit
      => @_call require(@_definitionFile), @_name
      => @_searchTests()
      => @_readyDeferred.resolve()
    ]
    @_readyDeferred.promise

  ###*
   * Search for test-files that use this environment.
   * @return {Array}
  ###
  _searchTests: (currentPath = @_basePath) =>
    if @_dontSearchTests
      @dslDisable()
      return

    d = Q.defer()

    #* Walk directory
    fs.readdir currentPath, (error, files) =>
      if error
        d.reject new Error(error)
        return

      if (currentPath != @_basePath)
        #* Stop walking if we can find a new definition in this folder.
        for matcher in @config.environments.definitions
          if minimatch.match(files, matcher, {}).length
            d.resolve()
            return

      subSearches = []

      files.forEach (file, i) =>
        fullPath = path.join currentPath, file

        #* If we have a directory, get recursive
        fs.lstat fullPath, (err, stat) =>
          if err
            d.reject new Error(err)
            return

          if stat.isDirectory()
            subSearches.push @_searchTests fullPath

          else
            #* Add file if it matches our test matchers.
            for matcher in @config.environments.tests
              if minimatch file, matcher
                @_tests.push fullPath

          if i == files.length - 1
            #* Wait for subdirectories to be done before resolving
            Q.all(subSearches).then d.resolve

    d.promise

#* Set the dependencies and export
KarmaEnvironment.$inject = Base.$inject.concat ['runner']
module.exports = KarmaEnvironment
