# HiD-Sitemap

A `sitemap.xml` generator for the HiD static site framework.

Produces a standards-compliant sitemap containing all published pages and
posts, with optional `<lastmod>` timestamps.

## Requirements

- Perl 5.14+
- [HiD](https://git.genehack.net/genehack/hid)
- Moose, DateTime, Path::Tiny

## Installation

```sh
cpanm byterazor::HiD::Sitemap
```

## Usage

Add `+byterazor::HiD::Sitemap` to the `plugins` key in your HiD config.
The `+` prefix tells HiD to use the full class name rather than looking in
the `HiD::Generator::` namespace:

```yaml
plugins:
  - '+byterazor::HiD::Sitemap'
sitemap:
  generate: 1
```

### Configuration

| Key | Default | Description |
| --- | --- | --- |
| `sitemap.generate` | `0` | Enable the generator. |
| `sitemap.destination` | `sitemap.xml` | Output path, relative to the site destination. |
| `sitemap.baseurl` | site `baseurl` | Absolute base URL prefixed to every entry. Sitemaps require absolute URLs; a warning is emitted if it is missing. |
| `sitemap.lastmod` | `1` | Include `<lastmod>` elements. For posts the post date is used, for pages the modification time of the input file. Set to `0` to omit. |
| `sitemap.exclude` | — | Arrayref of regexes; matching URLs are left out of the sitemap. |

## Examples

### Basic

```yaml
sitemap:
  generate: 1
  baseurl: 'https://example.com'
```

### Exclude drafts

```yaml
sitemap:
  generate: 1
  baseurl: 'https://example.com'
  exclude:
    - 'draft'
    - 'private'
```

## License

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
See [LICENSE](LICENSE).

## Author

Dominik Meyer \<dmeyer@federationhq.de\>
