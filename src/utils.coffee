_ = require 'underscore'

exports.isDirectory = (path) ->
    (path.slice -1) is '/'

exports.traverse = (obj, path='') ->
    for segment in _.compact path.split '.'
        obj = obj[segment]
    obj

exports.set = (obj, path, value) ->
    sub = obj
    segments = _.compact path.split '.'
    while segment = segments.shift()
        if segments.length > 1
            sub = sub[segment] ?= {}
        else
            sub[segment] = value
    obj

exports.namespace = (path) ->
    if path
        _.partial exports.set, _, path
    else
        _.extend

exports.kv = (key, value) ->
    wrapped = {}
    wrapped[key] = value
    wrapped

exports.string =
    unwrap: (str) ->
        str.replace /\W?\n/g, ' '