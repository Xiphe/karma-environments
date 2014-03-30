module.exports = function(environment) {
  environment
    .use(['jasmine'])
    .add(function(window) {
      window.lorem = 'ipsum';
    })
    .call(function(done, environment) {
      setTimeout(function() {
        environment.lib('another');
        done();
      }, 100);
    })
    .lib('sample');
};
