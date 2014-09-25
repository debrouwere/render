// Generated by CoffeeScript 1.8.0
(function() {
  var async, colors, consolidate, engineList, engineNames, engines, fs, logRender, printHTML, unwrap, utils, writeHTML, _,
    __slice = [].slice;

  fs = require('fs');

  fs.path = require('path');

  fs.mkdirp = require('mkdirp');

  async = require('async');

  _ = require('underscore');

  consolidate = require('consolidate');

  colors = require('colors');

  utils = require('./utils');

  unwrap = utils.string.unwrap;

  fs.path.isDirectory = utils.isDirectory;

  engines = _.pick(consolidate, function(value, key) {
    return value.render != null;
  });

  engineNames = _.keys(engines);

  engineList = engineNames.join(', ');

  writeHTML = function(path, html, callback) {
    var directory, mkdir, resolvedPath, write;
    directory = fs.path.dirname(path);
    resolvedPath = fs.path.resolve(path);
    mkdir = _.partial(fs.mkdirp, directory);
    write = _.partial(fs.writeFile, resolvedPath, html, {
      encoding: 'utf8'
    });
    return async.series([mkdir, write], callback);
  };

  printHTML = function(html, callback) {
    console.log(html);
    return utils.next(callback);
  };

  logRender = function() {
    var callback, destination, extra, _i;
    destination = arguments[0], extra = 3 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 1) : (_i = 1, []), callback = arguments[_i++];
    console.log("✓".bold.green, "rendered".grey, destination);
    if (typeof callback === 'function') {
      return utils.next(callback);
    }
  };

  module.exports = function(layoutTemplate, context, options, callback) {
    var destination, err, extension, language, layout, log, mtime, output, render, renderingEngine;
    layout = layoutTemplate.fill(context);
    extension = (fs.path.extname(layout)).slice(1);
    language = options.engine || extension;
    renderingEngine = engines[language];
    if (!renderingEngine) {
      if (options.engine) {
        throw new Error(unwrap("Could not find a templating engine matching " + options.engine + ". Supported languages: " + engineList));
      } else {
        throw new Error(unwrap("Could not find a templating engine matching the extension " + extension + ". Please use the --engine option to clarify which engine you'd like to use. Supported languages: " + engineList));
      }
    }
    if (context.constructor === Array) {
      if (options.key) {
        context = utils.kv(options.key, context);
      } else {
        throw new Error(unwrap("Cannot pass on context data: expected an object but received an array. Consider using the --key option to wrap your data in an object. Alternatively, use --many to treat each element of the array as a separate context."));
      }
    }
    if (options.output) {
      destination = options.output.fill(context);
      if (fs.path.isDirectory(destination)) {
        destination += 'index.html';
      }
      output = _.partial(writeHTML, destination);
    } else {
      output = printHTML;
    }
    if (options.output && options.newerThan && !options.force) {
      try {
        mtime = {
          context: (new Date(utils.traverse(context, options.newerThan))).getTime(),
          layout: (fs.statSync(layout)).mtime.getTime(),
          html: (fs.statSync(destination)).mtime.getTime()
        };
        if (mtime.html > mtime.context && mtime.html > mtime.layout) {
          return utils.next(callback, 'skipped');
        }
      } catch (_error) {
        err = _error;
      }
    }
    render = _.partial(renderingEngine, layout, context);
    log = _.partial(logRender, destination);
    return async.waterfall([render, output, log], function(err) {
      return callback(err, 'rendered');
    });
  };

}).call(this);