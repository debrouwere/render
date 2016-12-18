_ =
    compact: require 'lodash.compact'
    partial: require 'lodash.partial'
    extend: require 'lodash.assignin'

exports.round = (number, decimals=0) ->
    power = Math.pow 10, decimals
    (Math.round number * power) / power

exports.elapsed = (start, stop) ->
    difference = (stop - start) / 1000
    exports.round difference, 2

exports.next = (callback, args...) ->
    process.nextTick ->
        callback null, args...

exports.passthrough = (args..., callback) ->
    process.nextTick ->
        callback null

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
        if segments.length
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
