import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import gleam/pair
import gleam/string
import gleam/string_tree
import mellie/element.{type ElementTree, ElementNode, TextNode}
import mellie/internal/html
import presentable_soup as soup

/// Parses the given HTML into a full document (containing `html`, `head`, and `body` tags)
///
/// If the given HTML does not contain an `html` or `head`, they will be automatically added
/// and the given content will be put into the `body`
pub fn parse(html str: String) -> Result(ElementTree, String) {
  str
  |> html.parse
}

pub fn elements_to_string(el: List(ElementTree)) -> String {
  el
  |> list.map(html.element_to_string)
  |> string_tree.join("")
  |> string_tree.to_string
}

/// Transforms a tree recursively using the given element and text conversion functions
pub fn transform_tree(
  tree: ElementTree,
  elem: fn(String, List(#(String, String)), List(a)) -> a,
  text: fn(String) -> a,
) -> a {
  case tree {
    TextNode(text: t) -> text(t)
    ElementNode(tag:, attributes:, children:) ->
      elem(tag, attributes, children |> list.map(transform_tree(_, elem, text)))
  }
}

/// This is useful for tests but is not context dependant and may be incorrect in cases where internal HTML depends on formatting (e.g. `pre > span`). Uses `presentable_soup` under the hood
pub fn elements_to_string_pretty(el: List(ElementTree)) -> String {
  el
  |> list.map(transform_tree(_, soup.ElementNode, soup.TextNode))
  |> soup.elements_to_string
}

/// This is useful for tests but is not context dependant and may be incorrect in cases where internal HTML depends on formatting (e.g. `pre > span`). Uses `presentable_soup` under the hood
pub fn element_to_string_pretty(el: ElementTree) -> String {
  el |> list.wrap |> elements_to_string_pretty
}

pub fn element_to_string(el: ElementTree) -> String {
  html.element_to_string(el) |> string_tree.to_string
}

pub fn element_to_xml_string(el: ElementTree) -> String {
  html.element_to_xml_string(el) |> string_tree.to_string
}

pub fn element_to_xml_document_string(el: ElementTree) -> String {
  let content = el |> element_to_xml_string
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" <> content |> string.trim
}

const doctype_html: String = "<!doctype html>"

pub fn to_document_string(el: ElementTree) -> String {
  doctype_html <> "\n" <> element_to_string(el)
}

pub fn element(
  tag: String,
  attributes: List(#(String, String)),
  children: List(ElementTree),
) -> ElementTree {
  ElementNode(tag:, attributes:, children:)
}

pub fn text(text: String) -> ElementTree {
  TextNode(text)
}

/// Recursively get all text from given element
pub fn inner_text(el: ElementTree) -> String {
  case el {
    ElementNode(tag: _, attributes: _, children:) ->
      children |> list.map(inner_text) |> string.join("")
    TextNode(text) -> text
  }
}

pub fn attribute(name: a, value: b) -> #(a, b) {
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

pub fn has_tag(tree: ElementTree, tag: String) -> Bool {
  case tree {
    ElementNode(tag: t, attributes: _, children: _) -> tag == t
    _ -> False
  }
}

/// Gets the children of an element. `TextNode`s will return `[]`
pub fn children(tree: ElementTree) -> List(ElementTree) {
  case tree {
    ElementNode(tag: _, attributes: _, children:) -> children
    _ -> []
  }
}

/// Gets tag of the given element. `TextNode`s will return `None`
pub fn tag(tree: ElementTree) -> option.Option(String) {
  case tree {
    ElementNode(tag:, attributes: _, children: _) -> tag |> Some
    TextNode(_) -> None
  }
}

/// Gets attributes of the given element. `TextNode`s will return `[]`
pub fn attrs(tree: ElementTree) -> List(#(String, String)) {
  case tree {
    ElementNode(tag: _, attributes:, children: _) -> attributes
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

pub fn update_where(
  from in: ElementTree,
  where should_visit: fn(ElementTree) -> Bool,
  with update: fn(ElementTree) -> ElementTree,
) -> ElementTree {
  case should_visit(in) {
    False ->
      case in {
        TextNode(_) -> in
        ElementNode(tag: _, attributes: _, children:) ->
          ElementNode(
            ..in,
            children: children
              |> list.map(update_where(_, should_visit, update)),
          )
      }
    True -> update(in)
  }
}

pub fn update_where_tag(
  from in: ElementTree,
  tag tag: String,
  with update: fn(ElementTree) -> ElementTree,
) -> ElementTree {
  update_where(in, has_tag(_, tag), update)
}

/// Sets attributes on an `ElementNode`, does not modify a `TextNode`
pub fn set_attributes(
  el: ElementTree,
  attr: List(#(String, String)),
) -> ElementTree {
  case el {
    TextNode(_) -> el
    ElementNode(tag: _, attributes:, children: _) -> {
      let d = attributes |> dict.from_list

      let attrs =
        list.fold(attr, d, fn(acc, a) {
          dict.insert(acc, a |> pair.first, a |> pair.second)
        })
      ElementNode(..el, attributes: attrs |> dict.to_list)
    }
  }
}

/// Sets attributes on an `ElementNode`, does not modify a `TextNode`
pub fn set_attribute(el: ElementTree, attr: #(String, String)) -> ElementTree {
  set_attributes(el, [attr])
}

/// Removes attributes on an `ElementNode`, does not modify a `TextNode`
pub fn remove_attributes(el: ElementTree, attrs: List(String)) -> ElementTree {
  let keys = attrs |> list.map(pair.new(_, True)) |> dict.from_list
  let has_key = dict.has_key(keys, _)

  case el {
    TextNode(_) -> el
    ElementNode(tag: _, attributes:, children: _) ->
      ElementNode(
        ..el,
        attributes: attributes
          |> list.filter(fn(a) { a |> pair.first |> has_key }),
      )
  }
}

/// Removes attribute on an `ElementNode`, does not modify a `TextNode`
pub fn remove_attribute(el: ElementTree, attr: String) -> ElementTree {
  remove_attributes(el, [attr])
}

// Gets an attribute value from an element
pub fn attr(el: ElementTree, key: String) -> Result(String, Nil) {
  el |> attrs |> dict.from_list |> dict.get(key)
}

// Gets a data attribute's value given the data key name. Given `my-key`, will look for `data-my-key`
pub fn data_attr(el: ElementTree, data_key: String) -> Result(String, Nil) {
  el |> attrs |> dict.from_list |> dict.get("data-" <> data_key)
}
