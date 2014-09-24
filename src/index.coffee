_ = require 'underscore'
async = require 'async'
{PathExp} = require 'simple-path-expressions'
groupby = require 'groupby-cli'
context = require './context'
render = require './render'
utils = require './utils'
{unwrap} = utils.string


module.exports = (layoutPattern, outputPattern, contextEnum, globalsEnum, options, callback) ->
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
                "Found more than one dataset for #{offenders}.
                Pick an output filename template that produces a 
                unique filename for each dataset."

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

    renderingOptions = _.pick options, 'engine', 'key', 'newerThan', 'force'
    _.extend renderingOptions, 
        output: outputTemplate

    renderer = _.partial render, layoutTemplate, _, renderingOptions
    async.each contexts, renderer, callback
