import gleam/list
import gleam/option.{None, Some}
import gleam/string
import mellie/internal/html
import presentable_soup.{ElementNode, TextNode} as soup

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
  ElementNode(tag:, attributes:, children:)
}

pub fn text(text) {
  TextNode(text)
}

/// Recursively get all text from given element
pub fn inner_text(el: ElementTree) {
  case el {
    ElementNode(tag: _, attributes: _, children:) ->
      children |> list.map(inner_text) |> string.join("")
    TextNode(text) -> text
  }
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
    ElementNode(tag: t, attributes: _, children: _) -> tag == t
    _ -> False
  }
}

/// Gets the children of an element. `TextNode`s will return `[]`
pub fn children(tree: ElementTree) {
  case tree {
    ElementNode(tag: _, attributes: _, children:) -> children
    _ -> []
  }
}

/// Gets tag of the given element. `TextNode`s will return `None`
pub fn tag(tree: ElementTree) {
  case tree {
    ElementNode(tag:, attributes: _, children: _) -> tag |> Some
    TextNode(_) -> None
  }
}

/// Gets attributes of the given element. `TextNode`s will return `[]`
pub fn attrs(tree: ElementTree) {
  case tree {
    ElementNode(tag: _, attributes: _, children:) -> children
    _ -> []
  }
}

/// Gets children with the given tag up to one level of results. Use with `find_all` to recurse further into returned elements
pub fn get_children_by_tag(
  tree: ElementTree,
  tag: String,
) -> List(ElementTree) {
  tree
  |> children
  |> list.map(fn(child) {
    case has_tag(child, tag) {
      True -> [child]
      False -> get_children_by_tag(child, tag)
    }
  })
  |> list.flatten
}

/// Runs the given function recursively over the result until it no longer results in items.
/// Returns the found nodes from every level
pub fn find_all(from in: a, with fun: fn(a) -> List(a)) -> List(a) {
  let out = fun(in)
  let next = out |> list.map(find_all(_, fun)) |> list.flatten

  list.append(out, next)
}

/// Runs the given function recursively over the result until it no longer returns items.
/// Returns only the deepest matching nodes
pub fn find_leaf(from in: a, with fun: fn(a) -> List(a)) -> List(a) {
  fun(in)
  |> list.map(fn(o) {
    case find_all(o, fun) {
      [] -> [o]
      inner -> inner
    }
  })
  |> list.flatten
}
