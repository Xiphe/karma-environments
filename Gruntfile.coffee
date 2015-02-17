module.exports = (grunt) ->

  grunt.initConfig

    pkg: grunt.file.readJSON 'package.json'

    simplemocha:
      options:
        ui: 'bdd'
        grep: grunt.option('grep') || ''
        reporter: 'dot'
      unit:
        src: [
          'test/unit/mocha-globals.coffee'
          'test/unit/**/*Spec.coffee'
        ]
      parser:
        src: [
          'test/unit/mocha-globals.coffee'
          'test/unit/**/headerEnvironmentParserSpec.coffee'
        ]

    peg:
      headerEnvironment:
        src: 'lib/headerEnvironmentParser/parser.pegjs'
        dest: 'lib/headerEnvironmentParser/parser.js'

    karma:
      example:
        configFile: 'test/example/karma.conf.js'

    watch:
      andtestparser:
        files: ['lib/headerEnvironmentParser/*', 'test/**/*.coffee']
        tasks: ['test:parser']
      andtest:
        files: ['lib/**/*.coffee', 'test/**/*.coffee']
        tasks: ['test:unit']

    bump:
      options:
        updateConfigs: ['pkg']
        commitFiles: ['package.json']
        commitMessage: 'release v%VERSION%'
        pushTo: 'origin'

    'npm-publish':
      options:
        requires: ['test']
        abortIfDirty: true
        tag: 'latest'

    'npm-contributors':
      options:
        commitMessage: 'Update contributors'

    concurrent:
      test:
        options:
          logConcurrentOutput: true
        tasks: [
          'karma:example'
          'simplemocha:parser'
          'simplemocha:unit'
        ]


  # Load grunt tasks from NPM packages
  require('load-grunt-tasks') grunt

  grunt.registerTask 'build', ['peg:headerEnvironment']

  grunt.registerTask 'test', (suite) ->
    grunt.task.run ['build']

    if suite == 'parser'
      grunt.task.run ['simplemocha:parser']
    else if suite == 'unit'
      grunt.task.run ['simplemocha:unit']
    else if suite == 'karma'
      grunt.task.run ['karma:example']
    else
      grunt.task.run ['concurrent:test']

  grunt.registerTask 'release', 'Build, bump and publish to NPM.', (type) ->
    grunt.task.run [
      'npm-contributors'
      "bump:#{type||'patch'}:bump-only"
      'test'
      'bump-commit'
      'npm-publish'
    ]