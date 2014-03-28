module.exports = function(environment) {
  environment
    .use(['qunit'])
    .add(['sampleLib.js', 'anotherLib.js'], '../jasmineEnv/');
};
