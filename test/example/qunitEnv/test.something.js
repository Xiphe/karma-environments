/* jshint strict: false */ /* global module, test, ok, notEqual, equal, foo, bar, cookies */
module('test#something', {});

test('something', function() {
  ok(true);
});

test('something else', function() {
  notEqual('foo', 'fara');
});

test('lib present', function() {
  equal('bar', foo);
});

test('other lib present', function() {
  equal('mjummy', cookies);
});

test('bar func', function() {
  equal(false, bar.lorem());
});

