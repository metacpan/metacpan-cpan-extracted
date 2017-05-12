# WebService::Beeminder -  Perl wrapper around the Beeminder API.

## Using this module

If you just wish to use this module, then please install the latest release
from the CPAN:

    cpanm WebService::Beeminder

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
