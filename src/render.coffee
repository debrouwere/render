fs = require 'fs'
fs.path = require 'path'
fs.mkdirp = require 'mkdirp'
async = require 'async'
_ = require 'underscore'
consolidate = require 'consolidate'
utils = require './utils'
{unwrap} = utils.string
fs.path.isDirectory = utils.isDirectory


engines = _.pick consolidate, (value, key) -> value.render?
engineNames = _.keys engines
engineList = engineNames.join ', '


writeHTML = (path, html, callback) ->
    if fs.path.isDirectory path
        path += 'index.html'
    directory = fs.path.dirname path 
    resolvedPath = fs.path.resolve path
    mkdir = _.partial fs.mkdirp, directory
    write = _.partial fs.writeFile, resolvedPath, html, encoding: 'utf8'
    async.series [mkdir, write], callback

printHTML = (html, callback) ->
    console.log html
    process.nextTick callback


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
        output = _.partial writeHTML, destination
    else
        output = printHTML
    
    # only rerender when needed
    # TODO: if no key is specified, use the context file's mtime
    # (which is a poor substitute, but still)
    if options.output and options.newerThan and not options.fresh
        try
            mtime =
                context: (new Date utils.traverse context, options.newerThan).getTime()
                layout: (fs.statSync layout).mtime.getTime()
                html: (fs.statSync destination).mtime.getTime()

            if mtime.html > mtime.context and mtime.html > mtime.layout
                return callback null
        catch err

    render = _.partial renderingEngine, layout, context
    async.waterfall [render, output], callback
