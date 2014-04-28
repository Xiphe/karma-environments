/* global describe, it, expect */
/**
 * Foobar this is text so the headerEnv wont start in the first line
 *
 * Karma environment
 *   name: My testing environment
 *   active: true
 *   focus: false
 *   #clean: true
 *   use: mocha, chai
 *   add: jquery, test.mytest.js | bower
 *   remove: something.js
 *   custom: foo
 */

describe('some test', function() {
  'use strict';

  it('shouldnt event be executed', function() {
    expect(this).not.to.be.executed();
  });
});
