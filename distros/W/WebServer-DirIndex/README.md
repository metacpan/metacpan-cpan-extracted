# WebServer::DirIndex

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/davorg-cpan/webserver-dirindex/perltest.yml)
![CPAN Version](https://img.shields.io/cpan/v/WebServer-DirIndex)

Directory index data for web server listings.

## Synopsis

```perl
use WebServer::DirIndex;

my $di = WebServer::DirIndex->new(
  dir     => '/path/to/dir',
  dir_url => '/some/dir/',
);

# Get the list of file entries
my @files = $di->files;

# Generate an HTML directory index page
my $html = $di->to_html('/some/dir/');

# Generate a prettified HTML directory index page
my $html = $di->to_html('/some/dir/', 1);
```

## Description

This module reads a filesystem directory and builds the data required to
render a directory index page for a web server. It provides access to the
list of file entries and can generate an HTML page via
[WebServer::DirIndex::HTML](lib/WebServer/DirIndex/HTML.pm).

The distribution includes four modules:

- **WebServer::DirIndex** — reads a directory and exposes file entries.
- **WebServer::DirIndex::File** - contains details of a single file in the directory.
- **WebServer::DirIndex::HTML** — renders the HTML directory index page.
- **WebServer::DirIndex::CSS** — provides standard and "pretty" CSS stylesheets.

## Installation

```
perl Makefile.PL
make
make test
make install
```

## Dependencies

- [HTTP::Date](https://metacpan.org/pod/HTTP::Date)
- [Plack](https://metacpan.org/pod/Plack)
- [URI::Escape](https://metacpan.org/pod/URI::Escape)

## Code, bugs and questions

This module is available [on CPAN](https://metacpan.org/pod/WebServer::DirIndex).

The code is available [on GitHub](https://github.com/davorg-cpan/webserver-dirindex).

For any questions, bug reports or suggestions, please use the
[issue tracker](https://github.com/davorg-cpan/webserver-dirindex).

## Author

Dave Cross <dave@perlhacks.com>

## Copyright and Licence

Copyright (c) 2026 Magnum Solutions Limited. All rights reserved.

This is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.
