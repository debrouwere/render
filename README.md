# Render

[![Build Status](https://travis-ci.org/debrouwere/render.svg)](https://travis-ci.org/debrouwere/render)

Render is an advanced command-line interface that renders text or HTML from [Jade](http://jade-lang.com/) templates, [Handlebars](http://handlebarsjs.com/) templates, [Swig](http://paularmstrong.github.io/swig/) templates and pretty much [any other kind of templates](https://github.com/visionmedia/consolidate.js#supported-template-engines) you can think of.

Use it to generate your static site, to fill out code skeletons, to populate config files – anything you can think of.

Install with [NPM](https://www.npmjs.org/) (bundled with [node.js](http://nodejs.org/)): 

```shell
npm install render-cli -g
```

Render comes with an [ISC license](http://en.wikipedia.org/wiki/ISC_license).

### Features

* **dynamic output** by passing JSON or YAML data (a.k.a. context variables) to your template
* **one to many** means you can iterate over context data and render the same template once for each set of data
* a **generic interface** so you don't have to learn a different command-line utility for every templating language you'd like to give a try
* **flexible naming** with output paths that can vary based on the data, using path placeholders

### Context variables

Pass context variables to your templates with `--context <file>...` for dynamic rendering. Context can be YAML or JSON.

```sh
# no context
render page.jade
# context from a single file
render page.jade \
    --input page.json
# context from multiple files which will be 
# merged (if objects) or appended (if arrays)
render page.jade \
    --context globals.json,page.json
# specify globals separately (for clarity)
render page.jade \
    --context page.json \
    --globals globals.json
```

### One-to-one and one-to-many

Render a single page:

```sh
# output to `stdout`
render page.jade
# or redirect to wherever you like
render page.jade > hello-world.html
```

Render a single page with context:

```sh
# one template, one rendered html file
render page.jade \
    --context page.json
```

Pick your own output filename, optionally using information from the context: 

```sh
render page.jade \
    --context page.json
    --output 'pages/{title}'
```

Render multiple pages, one for each item in an array:

```sh
render tableofcontents.jade \
    --context pages.json
    --output 'pages/{permalink}'
    --many
```

If you'd like to iterate over the keys and values of an object instead, e.g. a url-to-title mapping, use:

```
render tableofcontents.jade \
    --context links.json
    --many-pairs
```

Each key will be available as `key`, each value as `value`.

The `--many` and `--many-pairs` options both accept an optional key to traverse to before iterating: 

```
render tableofcontents.jade \
    --context pages.json
    --output 'pages/{permalink}'
    --many results.pages
```

Useful if you don't have control over the input JSON and the array or object to iterate over is not at the root. Note that you can traverse multiple levels using dot notation, e.g. `results.data.pages`.

### Namespacing context data

You can pass more than one file to `render`. Objects will be merged, arrays will be appended to.

When merging different inputs would result in name clashes, you have the option of namespacing
the data from each input file.

Namespaces come in three flavors: 

Type      | Description               | Flag
----------|---------------------------|--------------------------------
explicit  | you pick the namespace    | --input (namespace):(filename)
automatic | the basename of the file  | --namespaced
automatic | the full path to the file | --fully-namespaced

#### Explicit namespaces

Explicit namespaces: put `globals.json` in a `globals` key rather than at the root of the context object.

```sh
render page.jade \
    --context globals:globals.json,page.json
```

```json
{
    "globals": {
        ...
    }, 
    "title": "data from page.json, not namespaced", 
    ...
}
```

#### Automatic namespaces

Automatic namespaces: inside of the context object, `globals.json` data will be available under `globals` and `page.json` data under `page`.

```sh
render page.jade \
    --input globals.json,page.json
    --namespaced
```

```json
{
    "globals": {
        ...
    }, 
    "page": {
        ...
    }
}
```

Automatic namespaces using the full path: `helpers/globals.json` will be accessible at `helpers.globals` and `page.json` will be under `page`.

```sh
render page.jade \
    --context helpers/globals.json,page.json
    --fully-namespaced
```

```json
{
    "helpers": {
        "globals": {
            ...
        }
    }, 
    "page": {
        ...
    }
}
```

Explicit namespaces take preference over automatic ones, so these globals will be available under `globals` rather than `helpers.globals`:

```sh
render page.jade \
    --context globals:helpers/globals.json,page.json
    --fully-namespaced
```

```
{
    "globals": {
        ...
    }, 
    "page": {
        ...
    }
}
```

### Dynamic output paths

Output paths can contain placeholders that will be interpolated to determine the final path to which to write the HTML for each rendered set of context. Think of your output path as a little template of its own.

If you're a web developer, this is similar to the kind of URL routing you see in web frameworks.

In a path like `build/{date}/{permalink}`, the `date` and `permalink` keys in your data determine where the final HTML ends up. This is especially useful when you ask render to iterate over your context data with `--many`, which will render and save each set of data separately.

Paths are interpolated using the exact same context data that was used to render your template.

Not just the output path, even the path to your template can be dynamic and based on the data. For example, `templates/{layout}.swig` will figure out which layout to use by looking for a `layout` key in your context variables. This means a single `render` command isn't limited to rendering just a single template.

Output paths that end in a slash will get `/index.html` tacked on the end.

Pattern                        | Context                  | Output
-------------------------------|--------------------------|-----------------------------
`posts/{permalink}.html`       | `permalink: hello-world` | posts/hello-world.html
`posts/{permalink}/`           | `permalink: hello-world` | posts/hello-world/index.html
`posts/{permalink}/index.html` | `permalink: hello-world` | posts/hello-world/index.html

### Supported template languages

By default, Render uses the templating language matching your extension (`.swig` for Swig, `.jade` for Jade). You can explicitly specify which renderer to use with the `--engine` option.

Supported engines include:

  - [atpl](https://github.com/soywiz/atpl.js)
  - [doT.js](https://github.com/olado/doT) [(website)](http://olado.github.io/doT/)
  - [dust (unmaintained)](https://github.com/akdubya/dustjs) [(website)](http://akdubya.github.com/dustjs/)
  - [dustjs-linkedin (maintained fork of dust)](https://github.com/linkedin/dustjs) [(website)](http://linkedin.github.io/dustjs/)
  - [eco](https://github.com/sstephenson/eco)
  - [ect](https://github.com/baryshev/ect) [(website)](http://ectjs.com/)
  - [ejs](https://github.com/visionmedia/ejs)
  - [haml](https://github.com/visionmedia/haml.js) [(website)](http://haml-lang.com/)
  - [haml-coffee](https://github.com/9elements/haml-coffee) [(website)](http://haml-lang.com/)
  - [hamlet](https://github.com/gregwebs/hamlet.js)
  - [handlebars](https://github.com/wycats/handlebars.js/) [(website)](http://handlebarsjs.com/)
  - [hogan](https://github.com/twitter/hogan.js) [(website)](http://twitter.github.com/hogan.js/)
  - [htmling](https://github.com/codemix/htmling)
  - [jade](https://github.com/visionmedia/jade) [(website)](http://jade-lang.com/)
  - [jazz](https://github.com/shinetech/jazz)
  - [jqtpl](https://github.com/kof/node-jqtpl) [(website)](http://api.jquery.com/category/plugins/templates/)
  - [JUST](https://github.com/baryshev/just)
  - [liquor](https://github.com/chjj/liquor)
  - [lodash](https://github.com/bestiejs/lodash) [(website)](http://lodash.com/)
  - [mote](https://github.com/satchmorun/mote) [(website)](http://satchmorun.github.io/mote/)
  - [mustache](https://github.com/janl/mustache.js)
  - [nunjucks](https://github.com/mozilla/nunjucks) [(website)](https://mozilla.github.io/nunjucks)
  - [QEJS](https://github.com/jepso/QEJS)
  - [ractive](https://github.com/Rich-Harris/Ractive)
  - [react](https://github.com/facebook/react)
  - [swig](https://github.com/paularmstrong/swig) [(website)](http://paularmstrong.github.com/swig/)
  - [templayed](http://archan937.github.com/templayed.js/)
  - [liquid](https://github.com/leizongmin/tinyliquid) [(website)](http://liquidmarkup.org/)
  - [toffee](https://github.com/malgorithms/toffee)
  - [underscore](https://github.com/documentcloud/underscore) [(website)](http://documentcloud.github.com/underscore/)
  - [walrus](https://github.com/jeremyruppel/walrus) [(website)](http://documentup.com/jeremyruppel/walrus/)
  - [whiskers](https://github.com/gsf/whiskers.js)

Render uses the [consolidate.js](https://github.com/visionmedia/consolidate.js) template engine consolidation library for all rendering. For more information on how to contribute a new template engine wrapper, please take a look at their documentation.

### Conditional rendering

If your context data includes a date in ISO format, you're in luck. Using the `--newer-than <key>` flag, you can tell render to only re-render if the context data is newer than the HTML that's already there.

The key flag indicates where in your data `render` can find the modified date.

This is particularly useful when iterating over multiple context sets: two or three sets of data might have changed but nothing else, and you shouldn't have to rerender all of it.

### Speed

The speed of `render` will depend on the complexity of your templates, the template engine and the speed of your CPU and hard drive. You can reasonably expect to be able to render about 10 to 20 pages per second.

IO is usually the bottleneck, even on machines with solid state drives, so `render` processes content serially to avoid filesystem contention.
