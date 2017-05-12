# WebService::Idonethis - Perl wrapper around idonethis.com

## Using this module

This implements a simple Perl front-end for the http://idonethis.com/ website.

See http://privacygeek.blogspot.com.au/2013/02/reimplementing-idonethis-memory-service.html
for an article on why this is useful and how to use its features.

This code can be found released on the CPAN as `WebService::Idonethis`.
The latest stable release can be installed with:

    cpanm WebService::Idonethis

## Developing this module

If you want to help _develop_ this module, then feel free to clone the
repo here. Contributions are greatly appreciated!

This project uses `Dist::Zilla` to take care of all boring parts of
development. To install Dist::Zilla, use your favourite CPAN installer:

    cpanm Dist::Zilla

Then:

    dzil authordeps | cpanm

For testing, use `dzil test`. If you want a traditional-looking module
directory in which to poke around, use `dzil build`.

