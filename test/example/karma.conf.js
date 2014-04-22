/* global require, module, __dirname */

// Karma configuration
// Generated on Tue Feb 11 2014 22:03:11 GMT+0100 (CET)
module.exports = function(config) {
  'use strict';
  var path = require('path');
  var basepath = path.dirname(path.dirname(__dirname));
  var environmentPlugin = path.join(basepath, 'lib/index.coffee');


  config.set({

    // base path, that will be used to resolve files and exclude
    basePath: '',

    plugins: [environmentPlugin, 'karma-*'],

    // frameworks to use
    frameworks: ['environments'],

    preprocessors: {
      '**/*.coffee': ['coffee']
    },

    // list of files / patterns to load in the browser
    files: [],

    environments: {
      tests: ['*Spec.+(coffee|js)', 'test.*.+(js|coffee)'],
      definitions: ['**/.karma.env.+(js|coffee)'],
      templateNamespace: 'ke-fixture',
      templates: ['*Fixture.html', 'template*.html'],
      customMethods: {
        lib: function(environment, args, done) {
          environment.add(args[0] + 'Lib.js');
          setTimeout(done, 100);
        }
      },
      customPaths: {
        jasmine: path.join(basepath, 'test/example/jasmineEnv')
      }
    },

    // list of files to exclude
    exclude: [],

    // test results reporter to use
    // possible values: 'dots', 'progress', 'junit', 'growl', 'coverage'
    reporters: ['dots'],

    // web server port
    port: 9876,

    // enable / disable colors in the output (reporters and logs)
    colors: true,

    // level of logging
    // possible values: config.LOG_DISABLE || config.LOG_ERROR ||
    // config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
    logLevel: config.LOG_INFO,

    // enable / disable watching file and executing tests whenever any file changes
    autoWatch: true,

    // Start these browsers, currently available:
    // - Chrome
    // - ChromeCanary
    // - Firefox
    // - Opera (has to be installed with `npm install karma-opera-launcher`)
    // - Safari (only Mac; has to be installed with `npm install karma-safari-launcher`)
    // - PhantomJS
    // - IE (only Windows; has to be installed with `npm install karma-ie-launcher`)
    browsers: ['PhantomJS'],

    // If browser does not capture in given timeout [ms], kill it
    captureTimeout: 60000,

    // Continuous Integration mode
    // if true, it capture browsers, run tests and exit
    singleRun: true
  });
};
