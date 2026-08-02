import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import htmgrrrl
import presentable_soup.{ElementNode, TextNode} as soup

pub fn element(tag, attrs, children) {
  ElementNode(tag, attrs, children)
}

pub fn text(text) {
  TextNode(text)
}

fn is_tag(el: soup.ElementTree, tag) {
  case el {
    ElementNode(tag: t, attributes: _, children: _) -> t == tag
    TextNode(_) -> False
  }
}

fn with_body(children) {
  children |> list.append([ElementNode("body", [], [])])
}

fn in_body(children) {
  [ElementNode("body", [], children)]
}

fn with_head(children) {
  [ElementNode("head", [], []), ..children]
}

fn ensure_root(root: soup.ElementTree) {
  case root {
    TextNode(_) ->
      ElementNode(
        "html",
        [],
        [root]
          |> in_body
          |> with_head,
      )
    ElementNode(tag:, attributes: _, children:) -> {
      let head = children |> list.find(is_tag(_, "head"))
      let body = children |> list.find(is_tag(_, "body"))

      case tag {
        "body" -> ElementNode("html", [], [root] |> with_head)
        "head" -> ElementNode("html", [], [root] |> with_body)
        "html" -> {
          case head, body {
            Ok(_), Ok(_) -> root
            Ok(_), Error(_) ->
              ElementNode(..root, children: children |> with_body)
            Error(_), Ok(_) ->
              ElementNode(..root, children: children |> with_head)
            Error(_), Error(_) -> {
              ElementNode(
                ..root,
                children: root.children |> in_body |> with_head,
              )
            }
          }
        }
        _ ->
          ElementNode("html", [], [
            ElementNode("head", [], []),
            ElementNode("body", [], [root]),
          ])
      }
    }
  }
}

type Curr {
  Curr(tag: String, attrs: List(#(String, String)))
}

fn to_elem(curr: Curr, children) {
  ElementNode(curr.tag, curr.attrs, children)
}

type State {
  State(
    parent: Option(State),
    /// current children
    children: List(soup.ElementTree),
    /// current tag + attrs
    curr: Option(Curr),
  )
}

fn add_child(state: State, c) {
  State(..state, children: state.children |> list.append([c]))
  |> Some
}

fn step_in(state: State, tag, attrs) {
  let new =
    Curr(
      tag,
      attrs |> list.map(fn(a: htmgrrrl.Attribute) { #(a.name, a.value) }),
    )

  State(parent: state |> Some, children: [], curr: new |> Some)
}

fn step_out(state: State) {
  case state.curr {
    None -> state.parent

    Some(curr) ->
      state.parent
      |> option.then(add_child(_, to_elem(curr, state.children)))
  }
}

@external(javascript, "./html_ffi.mjs", "parse")
pub fn parse_(html: String) -> Result(soup.ElementTree, String) {
  let state =
    htmgrrrl.sax(html, Some(State(None, [], None)), fn(state, _, ev) {
      case ev {
        htmgrrrl.StartElement(
          uri: _,
          local_name:,
          qualified_name: _,
          attributes:,
        ) -> {
          state |> option.map(step_in(_, local_name, attributes))
        }
        htmgrrrl.EndElement(uri: _, local_name: _, qualified_name: _) -> {
          state |> option.then(step_out)
        }
        htmgrrrl.Characters(text) | htmgrrrl.IgnorableWhitespace(text) ->
          state |> option.then(add_child(_, TextNode(text)))

        _ -> state
      }
    })

  use parsed <- result.try(
    state
    |> result.replace_error("sax parsing error"),
  )

  case parsed {
    Some(node) -> {
      let out =
        node.children
        |> list.first
        |> result.replace_error("no curr found")

      out
    }
    None -> Error("no root node found")
  }
}

pub fn parse(html) {
  html |> string.trim |> parse_ |> result.map(ensure_root)
}
