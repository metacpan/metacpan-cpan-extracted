[![Release](https://img.shields.io/github/release/giterlizzi/perl-URI-PackageURL.svg)](https://github.com/giterlizzi/perl-URI-PackageURL/releases) [![Actions Status](https://github.com/giterlizzi/perl-URI-PackageURL/workflows/linux/badge.svg)](https://github.com/giterlizzi/perl-URI-PackageURL/actions) [![License](https://img.shields.io/github/license/giterlizzi/perl-URI-PackageURL.svg)](https://github.com/giterlizzi/perl-URI-PackageURL) [![Starts](https://img.shields.io/github/stars/giterlizzi/perl-URI-PackageURL.svg)](https://github.com/giterlizzi/perl-URI-PackageURL) [![Forks](https://img.shields.io/github/forks/giterlizzi/perl-URI-PackageURL.svg)](https://github.com/giterlizzi/perl-URI-PackageURL) [![Issues](https://img.shields.io/github/issues/giterlizzi/perl-URI-PackageURL.svg)](https://github.com/giterlizzi/perl-URI-PackageURL/issues) [![Coverage Status](https://coveralls.io/repos/github/giterlizzi/perl-URI-PackageURL/badge.svg)](https://coveralls.io/github/giterlizzi/perl-URI-PackageURL)

# URI::PackageURL - Perl extension for Package URL (aka "purl")

## Synopsis

```.pl
use URI::PackageURL;

# OO-interface

# Encode components in PackageURL string
$purl = URI::PackageURL->new(type => cpan, namespace => 'GDT', name => 'URI-PackageURL', version => '2.21');

say $purl; # pkg:cpan/GDT/URI-PackageURL@2.21

# Parse PackageURL string
$purl = URI::PackageURL->from_string('pkg:cpan/GDT/URI-PackageURL@2.21');

# exported functions

$purl = decode_purl('pkg:cpan/GDT/URI-PackageURL@2.21');
say $purl->type;  # cpan

$purl_string = encode_purl(type => cpan, namespace => 'GDT', name => 'URI::PackageURL', version => '2.21');
```


## purl-tool a CLI for URI::PackageURL module

Inspect and export "purl" string in various formats (JSON, YAML, Data::Dumper, ENV):

```console
$ purl-tool pkg:cpan/GDT/URI-PackageURL@2.21 --json | jq
{
  "name": "URI-PackageURL",
  "namespace": "GDT",
  "qualifiers": {},
  "subpath": null,
  "type": "cpan",
  "version": "2.21"
}
```


Download package using "purl" string:

```console
$ wget $(purl-tool pkg:cpan/GDT/URI-PackageURL@2.21 --download-url)
```


Use "purl" string in your shell-scripts:

```.bash
#!bash

set -e 

PURL="pkg:cpan/GDT/URI-PackageURL@2.21"

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
            --version 2.21
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
 - https://metacpan.org/release/URI-PackageURL
 - https://github.com/package-url/purl-spec


## Copyright

 - Copyright 2022-2024 © Giuseppe Di Terlizzi
