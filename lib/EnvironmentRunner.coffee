Base = require './Base'
_    = require 'lodash'

###*
 * Interface for Environments to execute themselves.
###
class EnvironmentRunner extends Base
  constructor: -> super

  ###*
   * Run a test using given frameworks and environment files
   *
   * @param  {Array}    frameworks  names of frameworks
   * @param  {Array}    environment list of file paths
   * @param  {Fruncion} done        optional callback
   * @return {Boolean}
  ###
  run: (frameworks, environment, done = null) ->
    if done instanceof Function
      @bridge.doneCallbacks.push done

    #* Reset configuration files, as most frameworks will add themselves here.
    @config.files = _.clone @bridge.originalConfigFiles

    @bridge.setFrameworks frameworks

    #* Load the environment into our browsers.
    @fileList.reload @config.files.concat(@bridge.getPatterns environment), @config.exclude

    #* And schedule the test run.
    @executor.schedule()

EnvironmentRunner.$inject = Base.$inject.concat ['bridge', 'executor', 'fileList']
module.exports = EnvironmentRunner
