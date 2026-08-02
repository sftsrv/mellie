import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import gleam/pair
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

/// This is useful for tests but is not context dependant and may be incorrect in cases where internal HTML depends on formatting (e.g. `pre > span`)
pub fn element_to_pretty_string(el) {
  el |> list.wrap |> soup.elements_to_string
}

pub fn element_to_string(el) {
  html.element_to_string(el)
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

pub fn has_tag(tree: ElementTree, tag: String) {
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
) {
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
) {
  update_where(in, has_tag(_, tag), update)
}

/// Sets attributes on an `ElementNode`, does not modify a `TextNode`
pub fn set_attributes(el: ElementTree, attr) {
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
pub fn set_attribute(el: ElementTree, attr) {
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
