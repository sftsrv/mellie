// @ts-check
import { parseDocument, ElementType } from 'htmlparser2'

import { element, text }
  // @ts-expect-error JS-compiled version of html.gleam
  from './html.mjs'

import { Result$Ok, Result$Error }
  // @ts-expect-error relative this file's location in build/dev/javascript/web
  from "../../../prelude.mjs";

import { to_list as array_to_list }
  // @ts-expect-error relative this file's location in build/dev/javascript/web
  from '../../../gleam_javascript/gleam/javascript/array.mjs';

/**
 * @param {string} html
 */
export function parse(html) {
  try {
    const doc = parseDocument(html, {
      recognizeSelfClosing: true,
    })

    /**
     * @param {import('domhandler').ChildNode | import('domhandler').Document} node
     * @returns {object | undefined} parsed node
     */
    function convertNode(node) {
      if (node.type === ElementType.Text) {
        return text(node.data)
      }

      if (node.type === ElementType.Tag || node.type === ElementType.Script || node.type === ElementType.Style) {
        const attrs = node.attributes.map(a => [a.name, a.value])
        const children = node.children.map(convertNode).filter(Boolean)

        return element(node.name, array_to_list(attrs), array_to_list(children))
      }

      if (node.type === ElementType.Root) {
        // if the root contains anything other than the HTML node, then we move that to the top
        const html = node.children.find(c => c.type === ElementType.Tag && c.name === "html")
        if (html) {
          return convertNode(html)
        }

        const children = node.children.map(convertNode).filter(Boolean)
        return element("html", array_to_list([]), array_to_list(children))
      }

      return undefined
    }

    const result = convertNode(doc)
    return Result$Ok(result)
  } catch (err) {
    return Result$Error(`${err}`)
  }
}
