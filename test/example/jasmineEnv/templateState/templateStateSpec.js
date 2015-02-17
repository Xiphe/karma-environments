/* global describe, it, expect */
describe('template state', function() {
  'use strict';

  it('should have a template', function() {
    expect(document.getElementById('my-template')).not.toEqual(null);
    expect(document.getElementById('my-template').innerHTML).toBe('Hallo');
  });

  it('should be able to manipulate the template', function() {
    document.getElementById('my-template').innerHTML = 'Foo';
    expect(document.getElementById('my-template').innerHTML).toBe('Foo');
  });

  it('should reset the template for each test', function() {
    expect(document.getElementById('my-template').innerHTML).toBe('Hallo');
  });

  it('should not add the same template multiple times', function() {
    expect(document.getElementsByClassName('my-template').length).toBe(1);
  });
});
