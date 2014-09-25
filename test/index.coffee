_ = require 'underscore'
fs = require 'fs'
async = require 'async'
should = require 'should'
{exec} = require 'child_process'
{PathExp} = require 'simple-path-expressions'
{load} = require '../src/context'
render = require '../src/render'
process = require '../src'


loadJSON = (path) ->
    JSON.parse fs.readFileSync path, encoding: 'utf8'


describe 'internals', ->
    it 'can load one or more context files', ->
        context = load 'examples/data/hash-two.json'
        context.should.have.keys [
            'title'
            'body'
            ]

    it 'can namespace context using name:path identifiers', ->
        context = load 'example:examples/data/hash-two.json'
        context.should.have.key 'example'
        context.example.should.have.keys [
            'title'
            'body'
            ]

    it 'can namespace context using the basename', ->
        context = load 'examples/data/hash-two.json', namespaced: yes
        context.should.have.key 'hash-two'
        context['hash-two'].should.have.keys [
            'title'
            'body'
            ]

    it 'can namespace context using the full path', ->
        context = load 'examples/data/hash-two.json', fullyNamespaced: yes
        context.should.have.key 'examples'
        context.examples.should.have.key 'data'
        context.examples.data.should.have.key 'hash-two'
        context.examples.data['hash-two'].should.have.keys [
            'title'
            'body'
            ]

    it 'can merge context objects', ->
        examples = 'examples/data/hash-two.json,examples/data/hash-one.json'
        context = load examples
        # the title in hash-one should overwrite the title in hash-two
        # (hash-one is last in the list)
        context.title.should.eql 'Hello world!'
        context.body.should.eql 'Some content.'

    it 'can append context arrays', ->
        paths =
            one: 'examples/data/list-one.json'
            two: 'examples/data/list-two.json'
        one = loadJSON paths.one
        two = loadJSON paths.two
        titles = (_.pluck one, 'title').concat (_.pluck two, 'title')
        examples = "#{paths.one},#{paths.two}"
        context = load examples   
        context.length.should.eql one.length + two.length
        (_.pluck context, 'title').should.eql titles

    it 'will throw an error when trying to merge objects and arrays', ->
        paths =
            one: 'examples/data/hash-one.json'
            two: 'examples/data/list-one.json'    
        examples = "#{paths.one},#{paths.two}"        
        incompatible = ->
            load examples
        incompatible.should.throw()

    it 'can render a layout', (done) ->
        context =
            title: 'Just a little sanity check.'
        options =
            engine: 'swig'
        layoutTemplate = new PathExp 'examples/templates/detail.html'
        render layoutTemplate, context, options, (err, op) ->
            op.should.eql 'rendered'
            done err

    it 'can rerender only when needed', (done) ->
        ###
        This test corresponds to the command: 

            ./bin/render  \
                --context examples/data/list-one.json,examples/data/list-two.json \
                --output  \
                --newer-than \
                --verbose \
                --many

        ###

        layout = 'examples/templates/detail.jade'
        output = 'examples/html/{year}-{slug}.html'
        context = 'examples/data/list-one.json,examples/data/list-two.json'
        globals = ''
        options =
            newerThan: yes
            many: yes
        
        processOnce = _.partial process, layout, output, context, globals, options

        async.series [processOnce, processOnce], (err, stats) ->
            stats[0].rendered.should.eql 5
            stats[0].skipped.should.eql 0
            stats[1].rendered.should.eql 0
            stats[1].skipped.should.eql 5
            done err


describe 'command-line interface', ->
    it 'can render a layout', (done) ->
        command = "./bin/render examples/templates/detail.jade"
        exec command, (err, stdout, stderr) ->
            stdout.should.eql "<h1></h1>\n"
            done err

    it 'can render a layout with context', (done) ->
        command = "./bin/render examples/templates/detail.jade \
            --context examples/data/hash-one.json"
        exec command, (err, stdout, stderr) ->
            stdout.should.eql "<h1>Hello world!</h1>\n"
            done err

    it 'can dynamically decide which layout to render based on the context', (done) ->
        command = "./bin/render 'examples/templates/{category}.jade' \
            --context examples/data/hash-one.json"
        exec command, (err, stdout, stderr) ->
            stdout.should.eql "<h1>Hello world!</h1>\n"
            done err

    it 'can render to many HTML files at once', (done) ->
        command = "./bin/render 'examples/templates/detail.jade' \
            --context examples/data/list-one.json,examples/data/list-two.json \
            --output 'examples/html/{year}-{slug}.html' \
            --many"
        exec command, (err, stdout, stderr) ->
            files = fs.readdirSync 'examples/html'
            files.sort().should.eql [
                '2011-tintin.html'
                '2012-fathers-and-sons.html'
                '2012-oblomow.html'
                '2014-lucky-luke.html'
                '2014-mansfield-park.html'
                ]

            done err
