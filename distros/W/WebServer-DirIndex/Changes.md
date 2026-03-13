# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.3] - 2026-03-12

### Fixed

- Really fix the $VERSIONs this time
- Add some author tests

## [0.1.2] - 2026-03-11

### Fixed

- Set $VERSION the way our grandparents did

## [0.1.1] - 2026-03-10

### Fixed

- Minimal Perl version updated to 5.26.

## [0.1.0] - 2026-02-24

### Breaking changes

- The `pretty` option is now set when **creating** the `WebServer::DirIndex`
  object, not when calling `to_html`. If you were passing a second argument to
  `to_html`, move it to the constructor:

  ```perl
  # Before
  my $html = $di->to_html('/some/dir/', 1);

  # After
  my $di   = WebServer::DirIndex->new(dir => $dir, dir_url => '/', pretty => 1);
  my $html = $di->to_html('/some/dir/');
  ```

### Changed

- Enabling `pretty` now automatically enables icons as well. If you want the
  enhanced CSS but no icons, pass `icons => 0` explicitly.
- Icons remain enabled by default even when `pretty` is not set.

## [0.0.3] - 2026-02-23

### Added

- **File-type icons** — each entry in the listing now shows a
  [Font Awesome 6](https://fontawesome.com/) icon that matches the file's type
  (document, image, video, archive, etc.). The required stylesheet is loaded
  automatically from the Font Awesome CDN.
- New `icons` parameter on `WebServer::DirIndex->new` (defaults to true).
  Set `icons => 0` to produce a plain listing without icons.

## [0.0.2] - 2026-02-22

### Added

- New `WebServer::DirIndex::File` class representing a single file entry in a
  directory listing, with accessors for `url`, `name`, `size`, `mime_type`,
  `mtime`, and `icon`.

### Changed

- The `Plack` dependency has been removed. The module now uses `MIME::Types`
  for file-type detection and `HTML::Escape` for output escaping.

### Fixed

- Corrected the copyright year.

## [0.0.1] - 2026-02-21

### Added

- Initial release of `WebServer::DirIndex`, `WebServer::DirIndex::HTML`, and
  `WebServer::DirIndex::CSS`.

[Unreleased]: https://github.com/davorg-cpan/webserver-dirindex/compare/v0.0.1...HEAD
[0.0.1]: https://github.com/davorg-cpan/webserver-dirindex/releases/tag/v0.0.1
