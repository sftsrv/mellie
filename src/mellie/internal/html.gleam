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
  Curr(
    tag: String,
    attrs: List(#(String, String)),
    children: List(soup.ElementTree),
  )
}

type State {
  State(parent: Option(State), curr: Option(Curr))
}

@external(javascript, "./html_ffi.mjs", "parse")
pub fn parse_(html: String) -> Result(soup.ElementTree, String) {
  let state =
    htmgrrrl.sax(html, State(None, None), fn(acc, _, ev) {
      case ev {
        htmgrrrl.StartElement(
          uri: _,
          local_name:,
          qualified_name: _,
          attributes:,
        ) -> {
          State(
            parent: acc |> Some,
            curr: Curr(
              local_name,
              attributes |> list.map(fn(a) { #(a.name, a.value) }),
              [],
            )
              |> Some,
          )
        }
        htmgrrrl.EndElement(uri: _, local_name: _, qualified_name: _) -> {
          case acc.parent {
            Some(p) -> p
            None -> acc
          }

          State(acc.parent, None)
        }
        htmgrrrl.Characters(text) ->
          case acc.curr {
            Some(ElementNode(tag:, attributes:, children:)) ->
              ElementNode(
                tag:,
                attributes:,
                children: children |> list.append([TextNode(text)]),
              )
              |> Some
            _ -> acc.curr
          }
          |> State(parent: acc.parent, curr: _)
        _ -> acc
      }
    })

  echo state

  use parsed <- result.try(
    state
    |> result.replace_error("sax parsing error"),
  )

  case parsed.curr {
    Some(node) -> Ok(node)
    None -> Error("no root node found")
  }
}

pub fn parse(html) {
  html |> string.trim |> parse_ |> result.map(ensure_root)
}
