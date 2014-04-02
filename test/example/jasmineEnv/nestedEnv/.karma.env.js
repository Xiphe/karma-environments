module.exports = function(environment, path) {
  environment.add('nestedLib.js').remove('sampleLib.js', path.parent);
};
