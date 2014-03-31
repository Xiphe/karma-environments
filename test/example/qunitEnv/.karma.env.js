module.exports = function(environment, path) {
  environment
    .use(['qunit'])
    .add('sampleLib.js', path.jasmine)
    .add(path.jasmine('anotherLib.js'));
};
