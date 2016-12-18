fs = require 'fs'
fs.path = require 'path'
fs.mkdirp = require 'mkdirp'
async = require 'async'
_ =
    pickBy: require 'lodash.pickby'
    keys: require 'lodash.keys'
    partial: require 'lodash.partial'
consolidate = require 'consolidate'
colors = require 'colors'
utils = require './utils'
{unwrap} = utils.string
fs.path.isDirectory = utils.isDirectory


engines = _.pickBy consolidate, (value, key) -> value.render?
engineNames = _.keys engines
engineList = engineNames.join ', '


writeHTML = (path, html, callback) ->
    directory = fs.path.dirname path 
    resolvedPath = fs.path.resolve path
    mkdir = _.partial fs.mkdirp, directory
    write = _.partial fs.writeFile, resolvedPath, html, encoding: 'utf8'
    async.series [mkdir, write], callback

printHTML = (html, callback) ->
    console.log html
    utils.next callback

logRender = (destination, extra..., callback) ->
    console.log "✓".bold.green, "rendered".grey, destination
    if typeof callback is 'function'
        utils.next callback

module.exports = (layoutTemplate, context, options, callback) ->
    layout = layoutTemplate.fill context
    extension = (fs.path.extname layout)[1..]
    language = options.engine or extension
    renderingEngine = engines[language]

    unless renderingEngine
        if options.engine
            throw new Error unwrap \
            "Could not find a templating engine matching 
            #{options.engine}.

            Supported languages: #{engineList}"
        else
            throw new Error unwrap \
            "Could not find a templating engine matching 
            the extension #{extension}. Please use the --engine
            option to clarify which engine you'd like to use.

            Supported languages: #{engineList}"

    if context.constructor is Array
        if options.key
            context = utils.kv options.key, context
        else
            throw new Error unwrap \
            "Cannot pass on context data: expected 
            an object but received an array.

            Consider using the --key option to wrap
            your data in an object. Alternatively, 
            use --many to treat each element of the 
            array as a separate context."

    if options.output
        destination = options.output.fill context
        if fs.path.isDirectory destination
            destination += 'index.html'
        output = _.partial writeHTML, destination
    else
        output = printHTML

    if options.output and options.newerThan and not options.force
        try
            if options.newerThan.constructor is Date
                contextModified = options.newerThan               
            else
                contextModified = new Date utils.traverse context, options.newerThan

            mtime =
                context: contextModified.getTime()
                layout: (fs.statSync layout).mtime.getTime()
                html: (fs.statSync destination).mtime.getTime()

            if mtime.html > mtime.context and mtime.html > mtime.layout
                return utils.next callback, 'skipped'
        catch err

    if options.output and options.verbose
        log = _.partial logRender, destination
    else
        log = utils.passthrough

    render = _.partial renderingEngine, layout, context
    async.waterfall [render, output, log], (err) ->
        callback err, 'rendered'
