module.exports = function(environment) {
  environment
    .use(['jasmine'])
    .add(function(window) {
      window.lorem = 'ipsum';
    })
    .call(function(done, environment) {
      setTimeout(function() {
        environment.add('anotherLib.js');
        done();
      }, 100);
    })
    .add('sampleLib.js');
};
