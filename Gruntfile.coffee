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

  # Load grunt tasks from NPM packages
  require('load-grunt-tasks') grunt

  grunt.registerTask 'test', ['simplemocha:unit', 'shell:runkarma']

  grunt.registerTask 'release', 'Build, bump and publish to NPM.', (type) ->
    grunt.task.run [
      'npm-contributors'
      "bump:#{type||'patch'}:bump-only"
      'test'
      'bump-commit'
      'npm-publish'
    ]