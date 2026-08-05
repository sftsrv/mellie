# mellie

[![Package Version](https://img.shields.io/hexpm/v/mellie)](https://hex.pm/packages/mellie)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/mellie/)

A library for working with HTML that supports JavaScript and Erlang Targets

## Installation

```sh
gleam add mellie
```

`mellie` uses [`htmgrrrl`](https://htmgrrrl.hexdocs.pm/) for parsing on Erlang targets and [`htmlparser2`](https://www.npmjs.com/package/htmlparser2) for JavaScript targets

If targeting JavaScript, you also need to install `htmlparser2` using the relevant package manager:

```sh
# using npm
npm install htmlparser2@12

# or using pnpm
pnpm add htmlparser2@12
```

If targeting Erlang you shouldn't need to install any additional dependencies

## Usage

> Full documentation can be found at <https://hexdocs.pm/mellie>

### HTML Authoring

`mellie` provides functions to simplify authoring of HTML. These functions are generated from [MDN](https://developer.mozilla.org) and are provided in the `mellie.html` and `mellie.attr` namespaces

Parsing HTML can be done using the `parse` function. This will always return a full HTML document including the `html`, `head,` and `body` elements

```gleam
let input =
  "
<html>
  <head><title>Page Title</title></head>
  <body>
    <h1>Hello World</h1>
  </body>
</html>
"

let assert Ok(parsed) =
  input
  |> mellie.parse

parsed
|> mellie.to_document_string
|> birdie.snap("basic html parsing")
```

Elements can also be created using the provided `html` and `attr` functions for HTML elements and attributes respectively:

```gleam
let content =
  html.main([], [
    html.h1([], [html.text("My heading")]),
    html.p([attr.class("some-class")], [html.text("My body text")]),
  ])
```

Custom elements and attributes can also be defined using the `millie.element` and `millie.attribute` functions directly:

```gleam
let content =
  html.main([], [
    mellie.element("my-custom-element", [], [
      html.p([], [html.text("My body text")]),
    ]),
    html.br([]),
  ])
```

### Querying and Updating HTML

The package provides utilities for updating or querying the parsed HTML. Additionally, it has support for converting from `mellie.element.ElementTree` to other trees, for example a conversion to `presentable_soup` looks a bit like this:

```gleam
import presentable_soup as soup

let soup_tree = transform_tree(my_el, soup.ElementNode, soup.TextNode)
```

### HTML Parsing and Normalization

A primary of this package is to normalize behavior between JavaScript and Erlang environments for applications or libraries that target both. As platform deviation is considered a bug

Another important consideration of the library is to ensure that whitespace is retained to avoid subtle bugs when working with whitespace sensitive elements since this may be influenced by external CSS and as such can be context dependent

> See the [CSS `white-space` property doc](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/white-space) or the [HTML `pre` element doc](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/pre) on MDN for more information

## Development

Commands needed for development are outlined in [`maskfile.md`](/maskfile.md)

