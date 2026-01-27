[![Release](https://img.shields.io/github/release/giterlizzi/perl-URI-PackageURL.svg)](https://github.com/giterlizzi/perl-URI-PackageURL/releases) [![Actions Status](https://github.com/giterlizzi/perl-URI-PackageURL/workflows/linux/badge.svg)](https://github.com/giterlizzi/perl-URI-PackageURL/actions) [![License](https://img.shields.io/github/license/giterlizzi/perl-URI-PackageURL.svg)](https://github.com/giterlizzi/perl-URI-PackageURL) [![Starts](https://img.shields.io/github/stars/giterlizzi/perl-URI-PackageURL.svg)](https://github.com/giterlizzi/perl-URI-PackageURL) [![Forks](https://img.shields.io/github/forks/giterlizzi/perl-URI-PackageURL.svg)](https://github.com/giterlizzi/perl-URI-PackageURL) [![Issues](https://img.shields.io/github/issues/giterlizzi/perl-URI-PackageURL.svg)](https://github.com/giterlizzi/perl-URI-PackageURL/issues) [![Coverage Status](https://coveralls.io/repos/github/giterlizzi/perl-URI-PackageURL/badge.svg)](https://coveralls.io/github/giterlizzi/perl-URI-PackageURL)

# URI::PackageURL - Perl extension for PURL (Package URL) and VERS (Version Range)

## Synopsis

```perl
use URI::PackageURL;

# OO-interface

# Encode components in PURL string
$purl = URI::PackageURL->new(
  type      => 'cpan',
  namespace => 'GDT',
  name      => 'URI-PackageURL',
  version   => '2.25'
);

say $purl; # pkg:cpan/GDT/URI-PackageURL@2.25

# Parse a PURL string
$purl = URI::PackageURL->from_string('pkg:cpan/GDT/URI-PackageURL@2.25');


# use setter methods

my $purl = URI::PackageURL->new(type => 'cpan', namespace => 'GDT', name => 'URI-PackageURL');

say $purl; # pkg:cpan/GDT/URI-PackageURL
say $purl->version; # undef

$purl->version('2.25');
say $purl; # pkg:cpan/GDT/URI-PackageURL@2.25
say $purl->version; # 2.25


# exported functions

$purl = decode_purl('pkg:cpan/GDT/URI-PackageURL@2.25');
say $purl->type;  # cpan

$purl_string = encode_purl(type => cpan, namespace => 'GDT', name => 'URI-PackageURL', version => '2.25');
say $purl_string; # pkg:cpan/GDT/URI-PackageURL@2.25


# uses the legacy CPAN PURL type, to be used only for compatibility (will be removed in the future)

$ENV{PURL_LEGACY_CPAN_TYPE} = 1;
URI::PackageURL->new(type => 'cpan', name => 'URI::PackageURL');


# alias

$purl = PURL->new(
  type      => 'cpan',
  namespace => 'GDT',
  name      => 'URI-PackageURL',
  version   => '2.25'
);

$purl = PURL->from_string('pkg:cpan/GDT/URI-PackageURL');


# clone

$cloned = $purl->clone;

$cloned->version('1.00');

say $cloned; # pkg:cpan/GDT/URI-PackageURL@1.00
say $purl;   # pkg:cpan/GDT/URI-PackageURL@2.25
```


## purl-tool a CLI for URI::PackageURL module

Inspect and export "purl" string in various formats (JSON, YAML, Data::Dumper, ENV):

```console
$ purl-tool pkg:cpan/GDT/URI-PackageURL@2.25 --json | jq
{
  "name": "URI-PackageURL",
  "namespace": "GDT",
  "qualifiers": {},
  "subpath": null,
  "type": "cpan",
  "version": "2.25"
}
```


Download package using "purl" string:

```console
$ wget $(purl-tool pkg:cpan/GDT/URI-PackageURL@2.25 --download-url)
```


Use "purl" string in your shell-scripts:

```bash
#!bash

set -e 

PURL="pkg:cpan/GDT/URI-PackageURL@2.25"

eval $(purl-tool "$PURL" --env)

echo "Download $PURL_NAME $PURL_VERSION"
wget $PURL_DOWNLOAD_URL

echo "Build and install module $PURL_NAME $PURL_VERSION"
tar xvf $PURL_NAME-$PURL_VERSION.tar.gz

cd $PURL_NAME-$PURL_VERSION
perl Makefile.PL
make && make install
```


Create on-the-fly a "purl" string:

```console
$ purl-tool --type cpan \
            --namespace GDT \
            --name URI-PackageURL \
            --version 2.25
```


Validate a PURL string:

```bash
if $(purl-tool $PURL_STRING --validate -q); then
    echo "PURL string is valid"
else
    echo "PURL string is not valid"
fi
```


Display information about provided PURL type (allowed components, repository,
examples, etc.):

```console
$ purl-tool --info rpm
```

Display all known PURL types:

```console
$ purl-tool --list
```


## vers-tool a CLI for URI::VersionRange module

Decode a "vers" string:

```console
$ vers-tool "vers:cpan/1.00|>=2.00|<5.00" | jq
```

Check if a version is contained within a range:

```console
$ vers-tool "vers:cpan/1.00|>=2.00|<5.00" --contains "2.20"
```

Humanize "vers":

```console
$ vers-tool "vers:cpan/1.00|>=2.00|<5.00" --human-readable

cpan
- equal 1.00
- greater than or equal 2.00
- less than 5.00
```

## Install

Using Makefile.PL:

To install `URI::PackageURL` distribution, run the following commands.

    perl Makefile.PL
    make
    make test
    make install

Using App::cpanminus:

    cpanm URI::PackageURL


## Documentation

- `perldoc URI::PackageURL`
- `perldoc URI::VersionRange`
- https://metacpan.org/release/URI-PackageURL
- Specification: https://github.com/package-url/purl-spec
- TC54 - Software and system transparency: https://tc54.org
- ECMA-427 - Package-URL (PURL) specification: https://ecma-international.org/publications-and-standards/standards/ecma-427


## Copyright

- Copyright 2022-2026 © Giuseppe Di Terlizzi
