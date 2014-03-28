module.exports =
  ###*
   * Common name for all loggers.
   * @const
   * @type {String}
  ###
  LOGGER_NAMESPACE: 'environments'

  ###*
   * Default configuration
   * @const
   * @type {Object}
  ###
  DEFAULTS:
    definitions: ['**/.karma.env.+(js|coffee)']
    tests: ['**/*Spec.+(coffee|js)', '**/test.*.+(js|coffee)']
    asyncTimeout: 5000
