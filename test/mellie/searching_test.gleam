import birdie
import mellie

const nested_html = "
  <outer>
    <ignored>
      <inner>A</inner>
      <inner>B</inner>
      <inner>
          <inner>C</inner>
      </inner>
    </ignored>
  </outer>

"

pub fn find_element_by_tag_test() {
  let assert Ok(tree) = mellie.parse(nested_html)

  let assert Ok(child) =
    tree
    |> mellie.get_child_by_tag("inner")

  child
  |> mellie.element_to_string
  |> birdie.snap("find element by tag")
}

pub fn find_elements_by_tag_test() {
  let assert Ok(tree) = mellie.parse(nested_html)

  tree
  |> mellie.get_children_by_tag("inner")
  |> mellie.elements_to_string
  |> birdie.snap("find elements by tag")
}

pub fn find_elements_by_tag_recursively_test() {
  let assert Ok(tree) = mellie.parse(nested_html)

  tree
  |> mellie.find_all(mellie.get_children_by_tag(_, "inner"))
  |> mellie.elements_to_string
  |> birdie.snap("find elements by tag recursively")
}

pub fn find_elements_by_tag_leaf_test() {
  let assert Ok(tree) = mellie.parse(nested_html)

  tree
  |> mellie.find_leaf(mellie.get_children_by_tag(_, "inner"))
  |> mellie.elements_to_string
  |> birdie.snap("find elements by tag leaf")
}
