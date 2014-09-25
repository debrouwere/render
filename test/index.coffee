_ = require 'underscore'
fs = require 'fs'
should = require 'should'
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

    it 'will throw an error when it cannot figure out the template engine'
    it 'can render a layout'

describe 'command-line interface', ->
    it 'can render a layout'
    it 'can render a layout with context'
    it 'can dynamically decide which layout to render based on the context'
    it 'can render to many HTML files at once'
    it 'can rerender only when needed'
