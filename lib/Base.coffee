Q = require 'q'

configCache = {}

###*
 * Common setup for all our classes.
 * Set dependencies as instance variables and
 * initiate a logger.
###
class Base
  constructor: (modules...) ->
    #* Dynamically set all modules into the dependency object
    for module, i in @constructor.$inject
      @[module] = modules[i]

    #* Create a logger
    @logger = @logger.create "#{@constants.LOGGER_NAMESPACE}:#{@constructor.name}"
    @__setup()

  ###*
   * Execute a list of deferred objects with the option to fail on
   * every step
   * @param  {Array}  queue
   * @param  {Object} d     optional deferred object to cast on
   * @return {Object}       promise
  ###
  _runQueue: (queue, d = Q.defer()) ->
    result = Q()
    queue.push d.resolve
    queue.forEach (step) ->
      result = result.then(step).catch d.reject

    d.promise

  ###*
   * Set defaults and normalize configuration values
   * @return {void}
  ###
  __setup: ->
    return if @config.environments == configCache

    #* Ensure environment key is set in config
    if !@config.environments?
      @config.environments = {}

    for key, deflt of @constants.DEFAULTS
      #* Apply defaults
      if !@config.environments[key]?
        @config.environments[key] = deflt
      #* Ensure we have arrays when we expect them
      else if deflt instanceof Array and @config.environments[key] not instanceof Array
        @config.environments[key] = [@config.environments[key]]

    configCache = @config.environments

Base.$inject = ['logger', 'constants', 'config'];
module.exports = Base
