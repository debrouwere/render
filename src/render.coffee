fs = require 'fs'
fs.path = require 'path'
fs.mkdirp = require 'mkdirp'
_ = require 'underscore'
async = require 'async'
{PathExp} = require 'simple-path-expressions'
consolidate = require 'consolidate'
program = require 'commander'


program
    .version '0.1.0'
    .usage '<template> [options]'
    .option '-c --context <path>', 
        'Input files that serve as context to your template.'
    .option '-o, --output <path>', 
        'The path or path template.'
    .option '-l --line-delimited', 
        'Line-delimited JSON.'
    .option '-e, --engine <name>', 
        'The templating engine to use. If not specified, we guess from the extension.'
    .option '-n, --namespaced', 
        'Namespace JSON input by its filename.'
    .option '-N, --fully-namespaced', 
        'Namespace JSON input by its full path.'
    .option '-i, --iterate [key]',
        'Render a template once for each item.'
    .option '-g, --group [keys]', 
        'Group input by keys or output placeholders.'
    .option '-k, --key <name>', 
        'What name to give an array in the template context.'
    .parse process.argv


trace = (obj, path='') ->
    for segment in _.compact path.split '.'
        obj = obj[segment] ?= {}
    obj

unwrap = (str) ->
    str.replace /\W?\n/g, ' '

wrap = (obj, key) ->
    wrapped = {}
    wrapped[key] = obj
    wrapped

fs.path.isDirectory = (path) ->
    (path.slice -1) is '/'


for path in program.context.split(',')
    segments = path.split ':'
    path = segments.pop()
    name = segments.pop()
    extension = fs.path.extname path
    content = fs.readFileSync path, 'utf8'

    if program.lineDelimited
        data = content.split('\n').map JSON.parse
    else
        data = JSON.parse content

    if not contexts?
        switch data.constructor
            when Array
                contexts = []
                add = (items) -> contexts.push items...
            when Object
                contexts = {}
                add = (hash) -> _.extend contexts, hash
            else
                throw new Error()

    if data.constructor isnt contexts.constructor
        throw new Error "Mixed data types."

    if name and data.constructor isnt Object
        throw new Error()

    if contexts.constructor is Object and not name
        if program.namespaced
            name = fs.path.basename path, extension            
        else if program.fullyNamespaced
            base = path.replace extension, ''
            name = base.replace /\//g, '.'

    if name
        location = trace contexts, name 
        _.extend location, data
    else
        add data


if typeof contexts is 'array'
    groups = _.groupBy contexts, (obj) ->
        _.values _.pick obj, template.placeholders

    uniquelyIdentifies = _.every (_.values groups), (group) -> group.length is 1

    if not uniquelyIdentifies and not program.group
        throw new Error()

if program.group
    unless template.hasPlaceholders
        throw new Error()
    unless typeof context is 'array'
        throw new Error()
    context = groups


layoutTemplate = new PathExp program.args[0]
outputTemplate = new PathExp program.output or ''

isCollection = program.iterate or no

render = (context, callback) ->
    layout = layoutTemplate.fill context
    extension = (fs.path.extname layout)[1..]
    language = program.engine or extension
    engines = _.pick consolidate, (value, key) -> value.render?
    engineNames = _.keys engines
    engine = engines[language]
    unless engine
        if program.engine
            throw new Error unwrap \
                """Could not find a templating engine matching 
                #{program.engine}. Choose from #{engineNames}"""
        else
            throw new Error unwrap \
                """Could not find a templating engine matching 
                the extension #{extension}. Please use the --engine
                option to clarify which engine you'd like to use."""

    if context.constructor is Array
        context = wrap context, (program.key or 'items')

    consolidate[language] layout, context, (err, html) ->
        if err then return callback err

        if program.output
            destination = outputTemplate.fill context
            if fs.path.isDirectory destination
                destination += 'index.html'
            directory = fs.path.dirname destination
            fs.mkdirp directory, (err) ->
                if err
                    throw err
                else
                    fs.writeFile output, html, {encoding: 'utf8'}, callback
        else
            console.log html
            callback null

if not isCollection
    contexts = [contexts]

async.each contexts, render, (err) ->
    if err then console.log err
