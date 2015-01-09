karma-environments
==================

[![Build Status](https://travis-ci.org/Xiphe/karma-environments.svg?branch=v0.0.5)](https://travis-ci.org/Xiphe/karma-environments)
[![Dependency Status](https://david-dm.org/Xiphe/karma-environments.svg)](https://david-dm.org/Xiphe/karma-environments)

> Run multiple test suites in one karma process.  
> Watch multiple suites and execute only relevant ones on changes.

Designed for big projects with more than one JavaScripts App and/or multiple testing
frameworks in use.  
_(For example a backend JS App and some independent frontend snippets tested
in qUnit and Jasmine)._


__Tested with karma#0.12.31__


Installation
------------

```bash
npm install karma-environments --save-dev
```


Configuration
-------------
```js
// karma.conf.js
module.exports = function(config) {
  config.set({

  	/* Files are now managed by environment definitions.
  	 * It's recommended to leave this empty. */
  	files: [],

  	/* Global frameworks here.
  	 * It's recommended to add further frameworks inside environments */
    frameworks: ['environments'],

    environments: {
      /* Matcher for "Environment Definition Files" */
      definitions: ['**/.karma.env.+(js|coffee)'],
      /* Matcher for test Files relative to definition files. */
      tests: ['*Spec.+(coffee|js)', 'test.*.+(js|coffee)'],
      /* Matcher for template files relative to definition files. */
      templates: ['*Fixture.html', 'template*.html']
      /* Templates are wrapped with a div. Its class and id will use this prefix. */
      templateNamespace: 'ke'
      /* Timeout for asynchronous tasks. */
      asyncTimeout: 5000,
      /* Set true if environments should also be definable inside header comments of test files. */
      headerEnvironments: false,
      /* If you feel better with a delay between single environment runs, increase this value. */
      pauseBetweenRuns: 0,
      /* Extend the environment object used in definition files. */
      customMethods: {
        myLib: function(environment, args) {
          environment.add('my' + args[0] + 'Lib.js')
        }
      },
      customPath: {
        myPath: '/home/hannes/my-custom-things'
      }
    },

  });
};
```

Further configuration is done in [Environment Definition Files](#environment-definition-files)


Dependency Injection
--------------------

We're using [node di](http://github.com/vojtajina/node-di) for angular-style
dependency injection into following functions:

 * Exported functions of [Environment Definition Files](#environment-definition-files)
 * Sub-calls made by [environment.call()](#callfunction-function)
 * Custom methods defined in [configuration](#configuration)

Provided variables:

 * `environment` _(Object)_ - required! - The main environment DSL.
 * `path` _(Object)_ A helper Object for easy prefixing of files and paths. See [path helper](#path-helper)
 * `done` _(Function)_ Callback to determine when asynchronous tasks are done.
   If it is required, it needs do be called within `config.environments.asyncTimeout` milliseconds.
 * `error` _(Function)_ If something went wrong, calling this fails the entire environment.
 * `args` _(Array)_ Only for custom methods, The arguments passed in method call.


Environment Definition Files
----------------------------

* A New environment is created by creating a file (somewhere inside `config.basePath`)
  that matches with `config.environments.definitions` .

* An environment inherits frameworks and dependencies from its parents.
  (unless you `.clean()`)

* It searches for test files matching `config.environments.tests` in its directory
  and sub directories (unless they define a new environment).

### Example Definition

```js
// .karma.env.js
/**
 * Define a new environment.
 * All parameters are dependency injected (Order does not matter, but the name).
 * @see https://github.com/Xiphe/karma-environments#dependency-injection
 */
module.exports = function(environment) {
  /* The environment is chainable and has no properties */
  environment
    .name('My Environment')
    /* Disable this environment. */
    // .disable()
    /* Disable all other environments. */
    // .focus()
    /* Add one or multiple frameworks */
    .use(['jasmine'])

    /* Add a library or something we want to test */
    .add('foo.js')
    /* Add multiple things at once, and prefix all with a path. */
    .add(['lorem.js', 'ipsum.js'], 'blind/stuff')
    /* Add a temporary JS snippet. */
    .add(function(lorem) { lorem.setupTests(); })

    /* Make a subcall for whatever asynchronous stuff you want to do :) */
    .call(function(environment, done) {
      require('httpFoo').get('http://example.org/crazyExternalScript.js')
      .then(function(content) {
        environment.add(content);
        done();
      });
    })

    /* Call custom methods defined in karma.conf.js */
    .myLib('foo');
};

```

### Further Examples

See [example tests](https://github.com/Xiphe/karma-environments/tree/master/test/example).


Environment Definition Inside Test Files
----------------------------------------

If your environment has just one single test file, it feels a little much
to add another file just to declare the dependencies of the test.
CANT WE JUST ADD LIBRARIES IN THE TESTFILE ITSELF? - yup!
_As long as you have at least one [Environment Definition File](#environment-definition-files)
to declare the root of your testing folder_


```js
/* global foo */
/**
 * This is an example of an environment defined inside
 * a comment inside a test file. (yo dawg)
 *
 * Karma Environment
 *   # This line is ignored
 *   #active: false
 *   # Basically everything is a string
 *   add: myAwesomeLib.js
 *   # Pass multiple arguments to a method
 *   add: myOtherLib.js | the/folder/of/the/other/lib
 *   # false and true are converted to booleans
 *   focus: true
 *   # strings are split by comma so you can use arrays
 *   use: jasmine, chai
 * As soon as you break the indention level, the definition is done and
 * you can write some additional comments.
 */
describe('myAwesomeLib', function() {
  it('should exist', function() {
    expect(window.myAwesomeLib).toBeDefined();
  })
});
```

You may already have noticed, this is not suitable for the more complex environment definition
methods, such as [call](#callfunction-function) or [add](#addstringarrayfunction-libraries-string-prefix)
with a closure. If you need them you should stick to [Environment Definition Files](#environment-definition-files).


Environment DSL
---------------

This is the environment object which is injected into the functions of
[Environment Definition Files](#environment-definition-files).

Methods are executed one after another. This means libraries are always loaded into tests
in the correct order. Even if an asynchronous `.call()` is made.

### .name(_String_ name)
Overwrite the default name of the environment (which is generated from it's path).

### .activate()
Activate the environment (It's active by default).

### .disable()
Disable the environment

### .active([_Boolean_ onOff])
Set the activity to passed state (true by default).

### .focus()
Disable all other environments, multiple environments can be focused at the same time.

### .clean()
Forget everything added by `add()` and `use()` including inherited libraries and frameworks.

### .notests()
Do not search for or execute test files. Meaning this environment is just defining basics for it's children.

### .use(_String|Array_ frameworks)
Add one or multiple frameworks. See [Compatible Frameworks](#compatible-frameworks)

### .add(_String|Array|Function_ libraries[, _String_ prefix])
Add one or more libraries to the tests, optionally prefix them. The environm
Functions are wrapped into a closure and written into a temporary file witch is
then served in tests.

__Add File example__
```js
// one file
environment.add('myLib.js')
// Imports from: /{environmentBaseDir}/myLib.js, /myLib.js
environment.add(['myOtherLib.js', 'somethingElse.js'])
// Imports from: /{environmentBaseDir}/myOtherLib.js, /myOtherLib.js
//               /{environmentBaseDir}/somethingElse.js, /somethingElse.js
```

__Prefix Files__
```js
environment.add(['myOtherLib.js', 'somethingElse.js'], '/home/me/foo')
// Imports from: /{environmentBaseDir}/home/me/foo/myOtherLib.js,
//               /{environmentBaseDir}/myOtherLib.js,
//               /home/me/foo/myOtherLib.js, /myOtherLib.js,
//               (...same for somethingElse.js)
```

__Add Closure example__
```js
environment.add(function(jQuery) {
  jQuery('body').addClass('testFoo');
});
```
Leads to:
```js
// /tmp/sometempfile.js
(function(jQuery) {
  jQuery('body').addClass('testFoo');
})(jQuery);
```

### .remove(_String|Array_ libraries[, _String_ prefix])
Remove on or multiple previously added files.

### .call(_Function_ function)
Execute a sub-call. Witch behaves exactly like the function that is exported by definition files.

__Call example__
```js
environment.call(function(environment, done) {
  // Do something asynchronous here...
  require('httpFoo').get('http://example.org/someExternalScript.js').then(function(content) {
    environment.add(content);
    done();
  });
}).add('internalLib.js');
// someExternalScript.js will be loaded prior to internalLib.js since .add() will not be executed
// before done() is called
```


Custom Methods
--------------

You can add your own custom methods to the environment DSL.

See [configuration](#configuration), [example definition](#example-definition) and [dependency injection](#dependency-injection).


Path Helper
-----------

By using [dependency injection](#dependency-injection), we can use the `path` object for prefixing
files we want to `.add()`

```js
// some/.karma.env.js
module.exports = function(environment, path) {
  /* Explicitly get a file from root */
  environment.add(path.root('foo.js'))
  /* Prefix multiple files */
  .add(['a.js', 'b.js'], path.home);
  /* Use custom path helpers defined in configuration */
  .add(path.myPath + '/yes/it/uses/toString.js');
}
```


Shout Out
---------

 * Basic Idea and Starting Point inspired of [karma-sets](https://github.com/markgardner/karma-sets)
   by [Mark Gardner](https://github.com/markgardner)
 * Further improvements done at [Jimdo](https://github.com/Jimdo)


Compatible Frameworks
---------------------

Since this is a really deep intervention into how karma works by default.  
It's very much likely that this framework wont work along with some others
or destroy the functionality of them. See [Known Incompatibilities](#known-incompatibilities)

This frameworks have been tested and are working very well.

 * karma-jasmine#0.1.5
 * karma-qunit#0.1.1


Known Incompatibilities
-----------------------

 * [karma-coverage](https://github.com/karma-runner/karma-coverage)
   Will only generate coverage reports for the first environment being executed.

 * [karma-osx-reporter](https://github.com/petrbela/karma-osx-reporter)
   Will some times display this error in console:
   `ERROR [reporter.osx]: error: connect ECONNREFUSED`
   need to investigate that.

I think the main problem is, that some frameworks don't expect the `run_complete`
event to be emitted multiple times for the same browser.

A possible solution might be to prevent bubbling of the event and emit a single event
with the data of all environments in when we finished, but that might cause other troubles

Issues, Discussion and PR are welcome.


License
-------

[MIT](https://raw.github.com/Xiphe/karma-environments/master/LICENSE)
