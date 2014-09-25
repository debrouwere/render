describe 'internals', ->
    it 'can load one or more context files'
    it 'can namespace context using name:path identifiers'
    it 'can namespace context using the basename'
    it 'can namespace context using the full path'
    it 'can merge context objects'
    it 'can append context arrays'
    it 'will throw an error when trying to merge objects and arrays'
    it 'will throw an error when it cannot figure out the template engine'
    it 'can render a layout'

describe 'command-line interface', ->
    it 'can render a layout'
    it 'can render a layout with context'
    it 'can dynamically decide which layout to render based on the context'
    it 'can render to many HTML files at once'
    it 'can rerender only when needed'
