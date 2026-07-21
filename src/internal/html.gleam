import gleam/list
import gleam/result
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
  children |> list.append([element("body", [], [])])
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
          |> with_head
          |> with_body,
      )
    ElementNode(tag:, attributes: _, children:) ->
      case tag {
        "body" -> ElementNode("html", [], [root] |> with_head)
        "head" -> ElementNode("html", [], [root] |> with_body)
        "html" -> {
          let has_head = children |> list.any(is_tag(_, "head"))
          let has_body = children |> list.any(is_tag(_, "body"))

          case has_head, has_body {
            True, True -> root
            True, False -> ElementNode(..root, children: children |> with_body)
            False, True -> ElementNode(..root, children: children |> with_head)
            False, False ->
              ElementNode(
                ..root,
                children: root.children |> in_body |> with_head,
              )
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

@external(javascript, "./html_ffi.mjs", "parse")
pub fn parse_(html: String) -> Result(soup.ElementTree, String) {
  soup.element([soup.with_tag("html")])
  |> soup.return(soup.element_tree())
  |> soup.scrape(html)
  |> result.replace_error("presentable_soup error")
}

pub fn parse(html) {
  parse_(html) |> result.map(ensure_root)
}
