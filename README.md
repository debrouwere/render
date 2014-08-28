Render is a command-line interface that renders HTML from [Jade](http://jade-lang.com/) templates, [Handlebars](http://handlebarsjs.com/) templates, [Swig](http://paularmstrong.github.io/swig/) templates and pretty much any other kind of templates you can think of.

## Status

`Render` is still under heavy development. You might want to hold off on using it.

## Features 

* pass on **context variables** to your template
* **iterate** through your data and (optionally) render a page for each set of context
* **dynamic routes** through path interpolation means you have full control over where your HTML ends up on the filesystem

## Context

Pass context variables to your templates over `stdin` or with `--context` for dynamic rendering. Support for YAML and JSON and [line-delimited JSON](http://en.wikipedia.org/wiki/Line_Delimited_JSON).

```sh
# no context
render page.jade
# context from a single file
render page.jade \
    --input page.json
# context from multiple files which will be 
# merged (if objects) or appended (if arrays)
render page.jade \
    --input globals.json,page.json
```

### Namespacing


Explicit namespaces: put `globals.json` in a `globals` key rather than at the root of the context object.

```sh
render page.jade \
    --input globals:globals.json,page.json
```

Automatic namespaces: inside of the context object, `globals.json` data will be available under `globals` and `page.json` data under `page`.

```sh
render page.jade \
    --input globals.json,page.json
    --namespaced
```

Automatic namespaces using the full path: `helpers/globals.json` will be accessible at `helpers.globals` and `page.json` will be under `page`.

```sh
render page.jade \
    --input helpers/globals.json,page.json
    --fully-namespaced
```

Explicit namespaces take preference over automatic ones, so these globals will be available under `globals` rather than `helpers.globals`:

```sh
render page.jade \
    --input globals:helpers/globals.json,page.json
    --fully-namespaced
```

## One-to-one and one-to-many

Render a single page:

```sh
render page.jade
```

Render a single page with context:

```sh
# one template, one rendered html file
render page.jade \
    --input page.json
```

Render multiple pages, one for each item in an array:

```sh
render tableofcontents.jade \
    --input pages.json
    --output 'pages/{permalink}'
    --iterate
```

If the array to iterate over is not at the root of the JSON file but is an property on an object, specify the key to that property: 

```
render tableofcontents.jade \
    --input pages.json
    --iterate pages
```

Render one page for each language by grouping the data on that key: 

```
render feed.jade \
    --input posts.json
    --output 'feeds/{language}.atom'
    --group
    --iterate
```

The `group` option automatically figures out what to group on by looking at your the placeholders in your output path, though it is possible to pass one or more keys to the `--group` option to group explicitly.

## Path interpolation

Path interpolation works similar to the routing you're familiar with from web frameworks.

Interpolated paths determine which template to use and where output goes by specifying paths with placeholders, like `build/{date}/{permalink}`. Paths will be interpolated using the same context data that was used to render your template.

Not just output paths but also the path to your template can be dynamic and based on your data. For example, `templates/{layout}.swig` will figure out which layout to use by looking for a `layout` key in your context variables.

Output paths that end in a slash will get `/index.html` tacked on the end, so `posts/{permalink}.html` will result in filenames like `posts/hello-world.html` but `posts/{permalink}/` will become `posts/{permalink}/index.html` and thus will write that same content to `posts/hello-world/index.html`.

## Template languages

Render uses the [consolidate.js](https://github.com/visionmedia/consolidate.js) template engine consolidation library for all template rendering. Look at its documentation to find out all of the template languages supported by Render.
