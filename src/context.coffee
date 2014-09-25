fs = require 'fs'
fs.path = require 'path'
async = require 'async'
_ = require 'underscore'
yaml = require 'js-yaml'
utils = require './utils'
{unwrap} = utils.string


parsePaths = (paths=[], options) ->
    for path in _.compact paths.split(',')
        segments = path.split ':'
        filename = segments.pop()
        namespace = segments.pop()
        extension = fs.path.extname path

        # create the appropriate namespace-generating
        # function for this path
        unless namespace
            if options.fullyNamespaced
                namespace = fs.path.basename filename, extension    
            else if options.namespaced
                extensionlessFilename = filename.slice 0, -extension.length
                namespace = extensionlessFilename.replace /\//g, '.'            
        
        {filename, namespace}

readData = (path) ->
    resolvedPath = fs.path.resolve path
    fs.readFileSync resolvedPath, encoding: 'utf8'

parseData = (raw, extension) ->
    switch extension
        when '.json'
            JSON.parse raw
        when '.yml', '.yaml'
            yaml.safeLoad raw
        else
            throw new Error "Context files need to be JSON or YAML."

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

    for path in paths
        {filename, namespace} = path
        extension = fs.path.extname filename
        raw = readData filename
        path.data = parseData raw, extension

    merge paths...
