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
