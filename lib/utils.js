// Generated by CoffeeScript 1.12.4
(function() {
  var _,
    slice = [].slice;

  _ = require('underscore');

  exports.round = function(number, decimals) {
    var power;
    if (decimals == null) {
      decimals = 0;
    }
    power = Math.pow(10, decimals);
    return (Math.round(number * power)) / power;
  };

  exports.elapsed = function(start, stop) {
    var difference;
    difference = (stop - start) / 1000;
    return exports.round(difference, 2);
  };

  exports.next = function() {
    var args, callback;
    callback = arguments[0], args = 2 <= arguments.length ? slice.call(arguments, 1) : [];
    return process.nextTick(function() {
      return callback.apply(null, [null].concat(slice.call(args)));
    });
  };

  exports.passthrough = function() {
    var args, callback, i;
    args = 2 <= arguments.length ? slice.call(arguments, 0, i = arguments.length - 1) : (i = 0, []), callback = arguments[i++];
    return process.nextTick(function() {
      return callback(null);
    });
  };

  exports.isDirectory = function(path) {
    return (path.slice(-1)) === '/';
  };

  exports.traverse = function(obj, path) {
    var i, len, ref, segment;
    if (path == null) {
      path = '';
    }
    ref = _.compact(path.split('.'));
    for (i = 0, len = ref.length; i < len; i++) {
      segment = ref[i];
      obj = obj[segment];
    }
    return obj;
  };

  exports.set = function(obj, path, value) {
    var segment, segments, sub;
    sub = obj;
    segments = _.compact(path.split('.'));
    while (segment = segments.shift()) {
      if (segments.length) {
        sub = sub[segment] != null ? sub[segment] : sub[segment] = {};
      } else {
        sub[segment] = value;
      }
    }
    return obj;
  };

  exports.namespace = function(path) {
    if (path) {
      return _.partial(exports.set, _, path);
    } else {
      return _.extend;
    }
  };

  exports.kv = function(key, value) {
    var wrapped;
    wrapped = {};
    wrapped[key] = value;
    return wrapped;
  };

  exports.string = {
    unwrap: function(str) {
      return str.replace(/\W?\n/g, ' ');
    }
  };

}).call(this);
