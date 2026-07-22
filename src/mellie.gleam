import gleam/list
import mellie/internal/html
import presentable_soup as soup

pub type ElementTree =
  soup.ElementTree

pub fn parse(html str: String) {
  str
  |> html.parse
}

pub fn elements_to_string(el) {
  soup.elements_to_string(el)
}

pub fn element_to_string(el) {
  el |> list.wrap |> soup.elements_to_string
}

const doctype_html = "<!doctype html>"

pub fn to_document_string(el) {
  doctype_html <> "\n" <> element_to_string(el)
}

pub fn element(tag, attributes, children) {
  soup.ElementNode(tag:, attributes:, children:)
}

pub fn text(text) {
  soup.TextNode(text)
}

pub fn attribute(name, value) {
  #(name, value)
}

pub fn get_child_by_tag(
  tree: ElementTree,
  tag: String,
) -> Result(ElementTree, Nil) {
  let probe = has_tag(_, tag)

  let inner = tree |> children
  let found = inner |> list.find(probe)

  case found {
    Ok(_) -> found
    Error(_) -> inner |> list.find_map(get_child_by_tag(_, tag))
  }
}

fn has_tag(tree: ElementTree, tag: String) {
  case tree {
    soup.ElementNode(tag: t, attributes: _, children: _) -> tag == t
    _ -> False
  }
}

pub fn children(tree: ElementTree) {
  case tree {
    soup.ElementNode(tag: _, attributes: _, children:) -> children
    _ -> []
  }
}

/// Gets children with the given tag up to one level of results. Use with `find_all` to recurse further into returned elements
pub fn get_children_by_tag(
  tree: ElementTree,
  tag: String,
) -> List(ElementTree) {
  let children = tree |> children
  list.map(children, fn(child) {
    case has_tag(child, tag) {
      True -> [child]
      False -> get_children_by_tag(child, tag)
    }
  })
  |> list.flatten
}

/// Runs the given function recursively over the result until it no longer results in items
pub fn find_all(in: a, f: fn(a) -> List(a)) -> List(a) {
  let out = f(in)
  let next = out |> list.map(find_all(_, f)) |> list.flatten

  list.append(out, next)
}

/// Runs the given function recursively over the result until it no longer returns items
/// Returns only the deepest matching nodes
pub fn find_leaf(in: a, f: fn(a) -> List(a)) -> List(a) {
  f(in)
  |> list.map(fn(o) {
    case find_all(o, f) {
      [] -> [o]
      inner -> inner
    }
  })
  |> list.flatten
}
