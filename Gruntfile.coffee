module.exports = (grunt) ->

  grunt.initConfig

    simplemocha:
      options:
        ui: 'bdd'
        reporter: 'dot'
      unit:
        src: [
          'test/unit/mocha-globals.coffee'
          'test/unit/**/*Spec.coffee'
        ]

    shell:
      runkarma:
        options:
          stdout: true
          stderr: true
        command: 'node_modules/karma/bin/karma start test/example/karma.conf.js'

    watch:
      andtest:
        files: ['lib/**/*.coffee', 'test/**/*.coffee']
        tasks: ['test']

  # Load grunt tasks from NPM packages
  require('load-grunt-tasks') grunt

  grunt.registerTask 'test', ['simplemocha:unit', 'shell:runkarma']