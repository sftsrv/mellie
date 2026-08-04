pub type Attribute =
  #(String, String)

pub type ElementTree {
  ElementNode(
    tag: String,
    attributes: List(Attribute),
    children: List(ElementTree),
  )
  TextNode(text: String)
}
