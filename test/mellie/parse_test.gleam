import birdie
import mellie

const full_html = "<!doctype html>
<head>

</head>
<body>
<h2>Welcome!</h2>
<p>This is some content in Markdown that can be rendered to your site</p>
<p>Here&#39;s a code block and some other <em>fancy</em> formatting</p>
<my-custom-tag data='hello world'>
  <blockquote>
    <h2>Nested Heading</h2>
    <pre><code class='language-gleam'>code |&gt; print_me |&gt; echo
      </code></pre>
  </blockquote>
</my-custom-tag>
<script type='module' src='my/script/src'></script>
<script>
  console.log('some stuff')
  console.log('other stuff')
</script>
<style>
  .some-class {
    background-color: green;
  }
</style>
</body>
</html>"

pub fn parse_full_html_test() {
  let assert Ok(result) =
    full_html
    |> mellie.parse

  result
  |> mellie.element_to_string
  |> birdie.snap("html parsing and printing")
}

const partial_html = "
<h2>Welcome!</h2>
<p>This is some content in Markdown that can be rendered to your site</p>
<p>Here&#39;s a code block and some other <em>fancy</em> formatting</p>
"

pub fn parse_partial_html_test() {
  let assert Ok(result) =
    partial_html
    |> mellie.parse

  result
  |> mellie.element_to_string
  |> birdie.snap("partial html parsing and printing")
}

pub fn html_to_document_string_test() {
  let assert Ok(result) =
    full_html
    |> mellie.parse

  result
  |> mellie.to_document_string
  |> birdie.snap("html to document string")
}

pub fn basic_parse_test() {
  let input =
    "
  <html>
    <head><title>Page Title</title></head>
    <body>
      <h1>Hello World</h1>
    </body>
  </html>
"

  let assert Ok(parsed) =
    input
    |> mellie.parse

  parsed |> mellie.to_document_string |> birdie.snap("basic html parsing")
}
