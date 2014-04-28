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
    templates: ['*Fixture.html', 'template*.html']
    headerEnvironments: false
    templateNamespace: 'ke'
    asyncTimeout: 5000
    customMethods: {}
    pauseBetweenRuns: 0
    customPaths: {}
