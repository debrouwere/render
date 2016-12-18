fs = path: require 'path'
program = require 'commander'
colors = require 'colors'
_ =
    compact: require 'lodash.compact'
    pick: require 'lodash.pick'
    extend: require 'lodash.assignin'
render = require './'

program
    .version '0.3.1'
    .usage '<template> [options]'
    .option '-c --context <path>', 
        'Input files that serve as context to your template.', ''
    .option '-g --globals <path>', 
        'Data that will be added to each context set.', ''
    .option '-d --defaults <path>',
        'Data that will be added to each context set.
        This is just an alias: globals and defaults are merged together.', ''
    .option '-o --output <path>', 
        'The path or path template.'
    .option '-e --engine <name>', 
        'The templating engine to use. If not specified, we guess from the extension.'
    .option '-n --namespaced', 
        'Namespace JSON input by its filename.'
    .option '-N --fully-namespaced', 
        'Namespace JSON input by its full path.'
    .option '-t --newer-than [key]', 
        'Only render a context set if the output file does not yet exist, or the context is newer.
        The modified time for the newest context file will be used in comparisons.
        Alternatively, for data that will be iterated through, the context file its modified time 
        might not be the same as the modified time for the constituent sets of data.
        In this case, you may specify the key at which to find the context set its 
        modified date.'
    .option '-f --force', 
        'Rerender everything. Negates --newer-than (if specified)'
    .option '-F --fast', 
        'Speed up rendering by not checking whether each context set has a unique output path.'
    .option '-m --many [key]',
        'Render a template once for each item.'      
    .option '-p --many-pairs [key]', 
        'Render a template once for each key-value pair.'  
    .option '-k --key <name>', 
        'What name to give an array in the template context.'
    .option '-v --verbose', 
        'Output the path to each file being rendered.'
    .parse process.argv


context = program.context
globals = (_.compact [program.globals, program.defaults]).join ','

layoutPattern = program.args[0]
outputPattern = program.output

options = _.pick program, 
    'engine'
    'namespaced'
    'fullyNamespaced'
    'newerThan'
    'force'
    'fast'
    'key'
    'verbose'

many = options.many or options.manyPairs
root = if many?.constructor is String then many else null

_.extend options, 
    many: program.many or program.manyPairs
    pairs: program.manyPairs
    root: root

warn = (err) ->
    if err then console.log err.toString().red

render layoutPattern, outputPattern, context, globals, options, warn
