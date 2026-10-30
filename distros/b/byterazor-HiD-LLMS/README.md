# HiD-LLMS

An `llms.txt` generator for the HiD static site framework.

Produces an [llms.txt](https://llmstxt.org) -- a markdown-formatted index of
your site's pages and posts, designed to be read by large language models
instead of raw HTML. By default a companion `llms-full.txt` is produced as
well, containing the full markdown content of every page and post.

## Requirements

- Perl 5.14+
- [HiD](https://git.genehack.net/genehack/hid)
- Moose, Path::Tiny

## Installation

```sh
cpanm byterazor::HiD::LLMS
```

## Usage

Add `+byterazor::HiD::LLMS` to the `plugins` key in your HiD config.
The `+` prefix tells HiD to use the full class name rather than looking in
the `HiD::Generator::` namespace:

```yaml
plugins:
  - '+byterazor::HiD::LLMS'
llms:
  generate: 1
```

### Configuration

| Key | Default | Description |
| --- | --- | --- |
| `llms.generate` | `0` | Enable the generator. |
| `llms.title` | site `title` | The `#` heading of both files. Falls back to the site-wide `title` key; a warning is emitted and a placeholder used if neither is set. |
| `llms.description` | site `description` | A one-line site description, emitted as a blockquote below the title in `llms.txt`. Falls back to the site-wide `description` key; omitted if neither is set. |
| `llms.destination` | `llms.txt` | Output path for the index, relative to the site destination. |
| `llms.full` | `1` | Also generate `llms-full.txt` with the full markdown content of every page and post. Set to `0` to omit. |
| `llms.full_destination` | `llms-full.txt` | Output path for the full-content file, relative to the site destination. |
| `llms.baseurl` | site `baseurl` | Absolute base URL prefixed to every entry. The file is most useful with absolute URLs; a warning is emitted if it is not absolute. |
| `llms.exclude` | — | Arrayref of regexes; matching URLs are left out of both files. |

Pages are listed in URL order; posts are listed newest-first by date. Each
entry's link text is the post title for posts, the `title` front matter for
pages, or a title derived from the URL if none is given. A `description` from
the front matter is appended after the colon when present.

## Examples

### Basic

```yaml
llms:
  generate: 1
  title: 'My Site'
  description: 'A short one-line description.'
  baseurl: 'https://example.com'
```

### Exclude drafts

```yaml
llms:
  generate: 1
  baseurl: 'https://example.com'
  exclude:
    - 'draft'
    - 'private'
```

### Index only (no full file)

```yaml
llms:
  generate: 1
  baseurl: 'https://example.com'
  full: 0
```

## License

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
See [LICENSE](LICENSE).

## Author

Dominik Meyer \<dmeyer@federationhq.de\>
