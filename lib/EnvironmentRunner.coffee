Base = require './Base'
_    = require 'lodash'
path = require 'path'
hooks = path.join(__dirname, 'src/hook.js')

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

    envFiles = @bridge.getPatterns([hooks])
      .concat(@config.files)
      .concat(@bridge.getPatterns environment)

    #* Load the environment into our browsers.
    @fileList.reload(envFiles, @config.exclude).then =>

      #* And schedule the test run.
      setTimeout @executor.schedule, @config.environments.pauseBetweenRuns

EnvironmentRunner.$inject = Base.$inject.concat ['bridge', 'executor', 'fileList']
module.exports = EnvironmentRunner
