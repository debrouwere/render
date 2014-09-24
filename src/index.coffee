_ = require 'underscore'
async = require 'async'
colors = require 'colors'
{PathExp} = require 'simple-path-expressions'
groupby = require 'groupby-cli'
context = require './context'
render = require './render'
utils = require './utils'
{unwrap} = utils.string


module.exports = (layoutPattern, outputPattern, contextEnum, globalsEnum, options, callback) ->
    start = new Date()
    
    _.defaults options, 
        key: 'items'

    contexts = context.load contextEnum
    globals  = context.load globalsEnum
    layoutTemplate = new PathExp layoutPattern
    outputTemplate = new PathExp outputPattern or ''
    outputPlaceholders = _.pluck outputTemplate.placeholders, 'name'

    if options.root
        contexts = contexts[options.root]

    if options.pairs
        contexts = (_.pairs contexts).map ([key, value]) -> {key, value}

    if not options.many
        contexts = [contexts]

    if globals
        contexts.forEach (context) ->
            _.defaults context, globals

    if options.many and not options.fast
        offenders = groupby.clashes contexts, outputPlaceholders
        if offenders.length
            offenders = offenders.join ', '
            throw new Error unwrap \
                "Found more than one context set for #{offenders}.
                Pick an output filename template that produces a 
                unique filename for each set of context."

    if options.many
        unless outputTemplate.hasPlaceholders
            throw new Error unwrap \
                "Rendering a collection requires an output filename template 
                with placeholders, to avoid rendering each context set to the 
                same file."
        unless contexts.constructor is Array
            throw new Error \
                "Rendering a collection requires input in the form of an array.
                If your data is an object, consider specifying --many-pairs."

    renderingOptions = _.pick options, 
        'engine'
        'key'
        'newerThan'
        'force'
        'verbose'
    _.extend renderingOptions, 
        output: outputTemplate

    renderer = _.partial render, layoutTemplate, _, renderingOptions
    # unfortunately, parallel rendering leads to too much filesystem
    # contention to be of any use; it represents maybe a 2-3% 
    # performance gain; instead we've chosen to render serially
    async.mapSeries contexts, renderer, (err, operations) ->
        counts = _.countBy operations, _.identity
        _.defaults counts, 
            rendered: 'no'
            skipped: 'none'
        stop = new Date()
        preciseDuration = (stop - start) / 1000
        duration = utils.round preciseDuration, 2
        if options.verbose
            if counts.rendered isnt 'no' then console.log ''
            console.log unwrap \
            "Rendered #{counts.rendered.toString().bold} pages 
            and skipped #{counts.skipped.toString().bold} in 
            #{duration.toString().bold} seconds."

            callback err
