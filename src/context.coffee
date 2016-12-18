fs = require 'fs'
fs.path = require 'path'
async = require 'async'
_ =
    compact: require 'lodash.compact'
    extend: require 'lodash.assignin'
    pick: require 'lodash.pick'
    pluck: require 'lodash.pluck'
    max: require 'lodash.max'
confert = require 'confert'
utils = require './utils'
{unwrap} = utils.string


parsePaths = (paths=[], options={}) ->
    for path in _.compact paths.split(',')
        segments = path.split ':'
        filename = segments.pop()
        namespace = segments.pop()
        extension = fs.path.extname path

        # create the appropriate namespace-generating
        # function for this path
        unless namespace
            if options.fullyNamespaced
                extensionlessFilename = filename.slice 0, -extension.length
                namespace = extensionlessFilename.replace /\//g, '.'   
            else if options.namespaced
                namespace = fs.path.basename filename, extension             

        {filename, namespace}

# REFACTOR: this function can use a more rigorous rethink
merge = (sources...) ->
    for source in sources
        if source.data.constructor is Array and source.namespace
            source.data = utils.kv source.namespace, source.data
            source.namespace = no

        if not destination?
            switch source.data.constructor
                when Array
                    destination = []
                    add = (items) -> destination.push items...
                when Object
                    destination = {}
                    add = (hash) -> _.extend destination, hash
                else
                    throw new Error unwrap \
                    "Can only merge data from objects or arrays.
                    Instead got: #{source.constructor}"

        if source.data.constructor isnt destination.constructor
            throw new Error unwrap \
            "Mixed data types.
            Expected: #{destination.constructor.name}.
            Instead got: #{source.constructor.name}."

        if destination.constructor is Object and source.namespace
            utils.set destination, source.namespace, source.data
        else
            add source.data

    destination

exports.load = (pathList, options) ->
    paths = parsePaths pathList, (_.pick options, 'namespaced', 'fullyNamespaced')
    
    if not paths.length then return {}

    for path in paths
        {filename, namespace} = path
        extension = fs.path.extname filename
        path.data = confert fs.path.resolve filename

    merge paths...

exports.mtime = (pathList) ->
    paths = _.pluck (parsePaths pathList), 'filename'
    mtimes = paths
        .map fs.statSync
        .map (stats) -> stats.mtime
    _.max mtimes
