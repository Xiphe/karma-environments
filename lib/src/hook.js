(function(window, tc) {
  'use strict';

  var originalResult = tc.result;
  var originalComplete = tc.complete;
  var karmaEnvironments = {};
  var doneCallbacks = [];

  window.karmaEnvironments = karmaEnvironments;

  karmaEnvironments.onTestDone = function(callback) {
    doneCallbacks.push(callback);
  };

  tc.result = function() {
    originalResult.apply(originalResult, arguments);
    for (var i = 0, l = doneCallbacks.length; i < l; i++) {
      doneCallbacks[i]();
    }
  };

  tc.complete = function() {
    doneCallbacks = [];
    originalComplete.apply(originalComplete, arguments);
  };

})(window, window.__karma__);
