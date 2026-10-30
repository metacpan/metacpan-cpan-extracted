# HiD-BrokenLink

A broken link checker for the HiD static site framework.

After publishing, it scans the generated HTML, CSS and (optionally)
JavaScript files and verifies that every local reference — links,
images, stylesheets, scripts, inline `url()`s — points to a file that
actually exists in the destination.

## Requirements

- Perl 5.14+
- [HiD](https://git.genehack.net/genehack/hid)
- Moose, Path::Tiny, HTML::Parser

## Installation

```sh
cpanm byterazor::HiD::BrokenLink
```

## Usage

Add `+byterazor::HiD::BrokenLink` to the `plugins` key in your HiD
config. The `+` prefix tells HiD to use the full class name rather than
looking in the `HiD::Generator::` namespace:

```yaml
plugins:
  - '+byterazor::HiD::BrokenLink'
```

The check runs after publishing and is enabled by default.

### Configuration

| Key | Default | Description |
| --- | --- | --- |
| `brokenlink.enabled` | `1` | Run the check. |
| `brokenlink.check_html` | `1` | Check `href`/`src`/`data`/`poster` attributes and inline `<style>` blocks in HTML files. |
| `brokenlink.check_css` | `1` | Check `url()` references and `@import` statements in CSS files. |
| `brokenlink.check_js` | `0` | Check quoted root-relative asset references in JavaScript files. |
| `brokenlink.strip_baseurl` | `1` | Treat absolute URLs matching the site `baseurl` as local. |
| `brokenlink.exclude` | — | Arrayref of regexes; matching references are not checked. |
| `brokenlink.report` | — | Path of a text report listing the broken references, relative to the working directory (not the site destination). |
| `brokenlink.fail_on_broken` | `0` | Fail the build when broken references are found. |

### Link resolution

- External URLs (other schemes, other hosts), protocol-relative URLs
  and pure fragments are skipped.
- Query strings and fragments are stripped from the remaining links
  before they are checked.
- A link is OK if it matches an existing file or directory; a link with
  a trailing slash matches an existing directory or an `index.html`
  inside it, a link without a trailing slash also matches an
  `index.html` inside a directory of the same name.
- A `<base href>` element is respected when resolving relative
  references. A file with an external base URL is not checked at all.
- References that resolve outside the destination are reported as
  broken.

## Examples

### Basic

The plugin is enabled by default, no extra config is needed:

```yaml
plugins:
  - '+byterazor::HiD::BrokenLink'
```

### Fail the build on broken links

```yaml
brokenlink:
  fail_on_broken: 1
```

### Check JavaScript and write a report

```yaml
brokenlink:
  check_js: 1
  report: _reports/brokenlinks.txt
  exclude:
    - '\.min\.js$'
```

## License

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
See [LICENSE](LICENSE).

## Author

Dominik Meyer \<dmeyer@federationhq.de\>
