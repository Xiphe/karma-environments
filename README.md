karma-environments
==================

> Run multiple test suites in one karma process.
> Watch multiple suites and execute only relevant ones on changes.

Designed for big projects with more than one JavaScripts App and/or multiple testing
frameworks in use.
_(For example an backend JS App and some independent frontend snippets tested
in qUnit and Jasmine)._


### Tested with karma#0.10.9


Installation
------------

The easiest way is to keep `karma-environments` as a devDependency in your `package.json`.

```json
{
  "devDependencies": {
    "karma": "~0.10.9",
    "karma-environments": "~0.0.1"
  }
}
```

You can simple do it by:
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
      asyncTimeout: 5000
    },
  });
};
```

Further configuration is done in [Environment Definition Files](#environment-definition-files)


Environment Definition Files
----------------------------

* A New environment is created by adding a new directory containing a file that
  matches with `config.environments.definitions` inside config.basePath.

* An environment inherits frameworks and dependencies from its parents.
  (unless you `.clean()`)

* It searches for test files matching `config.environments.tests` in its directory
  and sub directories (unless they define a new environment).

### Full Example

```js
// .karma.env.js
/**
 * Define a new environment.
 * All parameters are dependency injected (Order does not matter, but the name).
 * @param {Object}   environment Required: The main environment DSL
 * @param {Function} done        Optional: Callback to determine when asynchronous
 *								 tasks are done.
 *                               If it is required, it needs do be called within
 *                               `config.environments.asyncTimeout` milliseconds.
 * @param {Function} error       Optional: If something went wrong, calling this
 *                               will fail the entire environment.
 */
module.exports = function(environment, done, error) {
  /* The environment is chainable and has no properties */
  environment
    /* Default name is generated using environments relative path */
    .name('My Environment')
    /* Environments are active by default. */
    .activate()
    /* Disable this environment. */
    .deactivate()
    /* Invert the active state. */
    .toggle()
    /* Disable all other environments. */
    .focus()
    /* Forget everything added until now (Including inherited data). */
    .clean()
    /* Do not search tests (Just define basics for child environments) */
    .notests()
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
      require('httpFoo').get('http://example.org/crazyExternalScript.js').then(function(content) {
        environment.add(content);
        done();
      });
    });

  /* Since we required done() we need to call it. */
  setTimeout(done, 123);
};

```

### Further Examples

See [example tests](https://github.com/Xiphe/karma-environments/tree/master/test/example).


Shout Out
---------

 * Basic Idea and Starting Point from [karma-sets](https://github.com/markgardner/karma-sets)
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
   Will only generate coverage reports for the first run.

 * [karma-osx-reporter](https://github.com/petrbela/karma-osx-reporter)
   Will some times display this error in console:
   `ERROR [reporter.osx]: error: connect ECONNREFUSED`
   need to investigate that.

I think the main problem is, that some frameworks don't expect the `run_complete`
event to be emitted multiple times for the same browser.

A possible solution might be to prevent bubbling of the event and emit a single event
with the data of all environments in when we finished, but that might cause other troubles

Issues, Discussion and PR are welcome.


Todo
----

 * Normalize internal method naming
 * Custom DSL Methods
 * Customizable Path helper
 * Update to Karma 12
 * Travis etc
 * Check actuality of dependencies
 * Banner Definitions


License
-------

[MIT](https://raw.github.com/Xiphe/karma-environments/master/LICENSE)
