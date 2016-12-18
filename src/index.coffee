_ =
    defaults: require 'lodash.defaults'
    pluck: require 'lodash.pluck'
    pairs: require 'lodash.pairs'
    pick: require 'lodash.pick'
    extend: require 'lodash.assignin'
    partial: require 'lodash.partial'
    countBy: require 'lodash.countBy'
    identity: require 'lodash.identity'
async = require 'async'
colors = require 'colors'
{PathExp} = require 'simple-path-expressions'
groupby = require 'groupby-cli'
context = require './context'
render = require './render'
utils = require './utils'
{unwrap} = utils.string


timing = {}

describe = (timing, counts) ->
    rps = utils.round counts.rendered / (utils.elapsed timing.render, timing.stop), 2
    duration = utils.elapsed timing.start, timing.stop

    if counts.rendered then console.log ''
    console.log unwrap \
    "Processed #{counts.rendered.toString().bold} pages.
    Skipped #{counts.skipped.toString().bold} pages."
    if counts.rendered
        console.log unwrap \
        "Rendered #{rps.toString().bold} pages per second, 
        took #{duration.toString().bold} seconds in total."

module.exports = (layoutPattern, outputPattern, contextEnum, globalsEnum, options, callback) ->
    timing.start = new Date()
    
    _.defaults options, 
        key: 'items'

    contexts = context.load contextEnum
    globals  = context.load globalsEnum
    layoutTemplate = new PathExp layoutPattern
    if outputPattern
        outputTemplate = new PathExp outputPattern
        outputPlaceholders = _.pluck outputTemplate.placeholders, 'name'
    else
        outputTemplate = no
        outputPlaceholders = []

    # if no --newer-than date key is specified, use
    # the newest context file's mtime instead
    # (in some cases this works really well, 
    # in others not at all)
    if options.newerThan and typeof options.newerThan isnt 'string'
        options.newerThan = context.mtime [contextEnum, globalsEnum].join ','

    if options.root
        contexts = utils.traverse contexts, options.root

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
        output: outputTemplate or no

    renderer = (context, callback) -> render layoutTemplate, context, renderingOptions, callback
    # unfortunately, parallel rendering leads to too much filesystem
    # contention to be of any use; it represents maybe a 2-3% 
    # performance gain; instead we've chosen to render serially
    timing.render = new Date()
    async.mapSeries contexts, renderer, (err, operations) ->
        timing.stop = new Date()
        counts = _.countBy operations, _.identity
        _.defaults counts, 
            rendered: 0
            skipped: 0

        if options.verbose
            describe timing, counts

        callback err, counts
