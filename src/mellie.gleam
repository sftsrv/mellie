import gleam/list
import internal/html
import presentable_soup as soup

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

pub fn element(tag, attributes, children) {
  soup.ElementNode(tag:, attributes:, children:)
}

pub fn text(text) {
  soup.TextNode(text)
}

pub fn attribute(name, value) {
  #(name, value)
}
