import attr
import birdie
import html
import mellie

pub fn html_basic_test() {
  let content =
    html.main([], [
      html.h1([], [html.text("My heading")]),
      html.p([attr.class("some-class")], [html.text("My body text")]),
    ])

  content
  |> mellie.element_to_string
  |> birdie.snap("some html content")
}

pub fn html_custom_test() {
  let content =
    html.main([], [
      mellie.element("my-custom-element", [], [
        html.p([], [html.text("My body text")]),
      ]),
      html.br([]),
    ])

  content
  |> mellie.element_to_string
  |> birdie.snap("some custom content")
}
