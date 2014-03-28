module.exports =
  #* Define our framework factory
  'framework:environments': ['factory', (injector) ->
    #* Create a child of the main injector, adding our own modules.
    injector.createChild([
      constants: ['value', require './constants']
      bridge: ['type', require './KarmaBridge']
      controller: ['type', require './EnvironmentController']
      runner: ['type', require './EnvironmentRunner']
    ])
    #* And Start the framework by hooking into karma.
    .invoke (bridge) ->
      bridge.init()
  ]
