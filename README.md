Render is an advanced command-line interface that renders HTML from [Jade](http://jade-lang.com/) templates, [Handlebars](http://handlebarsjs.com/) templates, [Swig](http://paularmstrong.github.io/swig/) templates and pretty much any other kind of templates you can think of.

Render comes with an [ISC license](http://en.wikipedia.org/wiki/ISC_license).

### Features

* **dynamic output** by passing JSON or YAML data (a.k.a. context variables) to your template
* **one to many** means you can iterate over context data and render the same template once for each row of data.
* a **generic interface** so you don't have to learn a different command-line utility for every templating language you'd like to give a try
* **flexible naming** because your output path can specify placeholders and be a little template of its own.

### Context variables

Pass context variables to your templates over `stdin` or with `--context <file>...` for dynamic rendering. Context can be YAML or JSON.

```sh
# no context
render page.jade
# context from stdin
cat page.json | render page.jade
# context from a single file
render page.jade \
    --input page.json
# context from multiple files which will be 
# merged (if objects) or appended (if arrays)
render page.jade \
    --input globals.json,page.json
```

### One-to-one and one-to-many

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
    --many
```

If the array to iterate over is not at the root of the JSON file but is an property on an object, specify the key to that property: 

```
render tableofcontents.jade \
    --input pages.json
    --many pages
```

If you'd like to iterate over the keys and values of an object instead, e.g. a url-to-title mapping, use:

```
render tableofcontents.jade \
    --input links.json
    --many-pairs
```

Each key will be available as `key`, each value as `value`.

### Namespacing context data

You can pass more than one file to `render`. Objects will be merged, arrays will be appended to.
When merging different inputs would result in name clashes, you have the option of namespacing
the data from each input file.

Namespaces come in three flavors: 

Type      | Description                            | Flag
----------|----------------------------------------|--------------------------------
explicit  | you pick the namespace                 | --input (namespace):(filename)
automatic | the basename of the file               | --namespaced
automatic | and verbose: the full path of the file | --fully-namespaced

#### Explicit namespaces

Explicit namespaces: put `globals.json` in a `globals` key rather than at the root of the context object.

```sh
render page.jade \
    --input globals:globals.json,page.json
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
    --input helpers/globals.json,page.json
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
    --input globals:helpers/globals.json,page.json
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

Output paths can contain placeholders that will be interpolated to determine the final output filename for each rendered set of context. Think of your output path as a little template of its own.

If you're a web developer, this is all very similar to the kind of URL routing you're familiar with from web frameworks.

In a path like `build/{date}/{permalink}`, the `date` and `permalink` keys in your data determine where the final HTML is saved to. This is especially useful when you ask render to iterate over your context data and render a separate file for each row of data.

Paths are interpolated using the exact same context data that was used to render your template.

Not just the output path, even the path to your template can be dynamic and based on the data. For example, `templates/{layout}.swig` will figure out which layout to use by looking for a `layout` key in your context variables. This means a single `render` command isn't limited to rendering just a single template.

Output paths that end in a slash will get `/index.html` tacked on the end.

Pattern                        | Context                  | Output
-------------------------------|--------------------------|-----------------------------
`posts/{permalink}.html`       | `permalink: hello-world` | posts/hello-world.html
`posts/{permalink}/`           | `permalink: hello-world` | posts/hello-world/index.html
`posts/{permalink}/index.html` | `permalink: hello-world` | posts/hello-world/index.html

### Supported template languages

Render uses the [consolidate.js](https://github.com/visionmedia/consolidate.js) template engine consolidation library for all template rendering. Look at its documentation to find out all of the template languages supported by Render.

### Partial rerendering

If your context data includes a date in ISO format, you're in luck. Using the `--newer-than <key>` flag, you can tell render to only re-render if the context data is newer than the HTML that's already there.

The key flag indicates where in your data `render` can find the modified date.

This is particularly useful when iterating over multiple context sets: two or three rows of data might have changed but nothing else, and you shouldn't have to rerender all of it.
