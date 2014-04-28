/* global describe, it, expect, fara, cookies */
/**
 * This demonstrates the setup of an environment
 * inside the Test-file by specifying it inside
 * the banner comment.
 *
 * Karma environment
 *   #active: false
 *   #focus: true
 *   clean: true
 *   use: jasmine
 *   add: fooLib.js | qunit
 *   lib: another
 */
describe('Header Environment', function() {
  'use strict';

  it('should not know foo, since it has been cleared', function() {
    expect(window.foo).toBeUndefined();
  });

  it('should know fara', function() {
    expect(fara).toBe('red');
  });

  it('should know about cookies,', function() {
    expect(cookies).toBe('mjummy');
  });
});
