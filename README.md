# mellie

A library for working with HTML that supports JavaScript and Erlang Targets

[![Package Version](https://img.shields.io/hexpm/v/mellie)](https://hex.pm/packages/mellie)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/mellie/)

## Installation

```sh
gleam add mellie
```

If targeting JavaScript, you also need to install `htmlparser2` using the relevant package manager:

```sh
# using npm
npm install htmlparser2@12

# or using pnpm
pnpm add htmlparser2@12
```

## Usage

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

Further documentation can be found at <https://hexdocs.pm/mellie>

## Development

Commands needed for development are outlined in [`maskfile.md`](/maskfile.md)


