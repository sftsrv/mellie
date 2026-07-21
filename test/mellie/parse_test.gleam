import birdie
import gleam/list
import mellie
import presentable_soup

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
  |> list.wrap
  |> presentable_soup.elements_to_string
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
  |> list.wrap
  |> presentable_soup.elements_to_string
  |> birdie.snap("partial html parsing and printing")
}
