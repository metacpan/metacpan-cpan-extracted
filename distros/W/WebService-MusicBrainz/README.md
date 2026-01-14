# WebService-MusicBrainz

This module will search the MusicBrainz database through their web service and
return objects with the found data.  This module is not backward compatible
with pre-1.0 versions.  Version 1.0 is a complete re-write based on
Mojolicious and implements [MusicBrainz Web Service Version
2](https://musicbrainz.org/doc/Development/XML_Web_Service/Version_2).

## INSTALLATION

To install this module, using the ExtUtils::MakeMaker method:

     perl Makefile.PL
     make
     make test
     make install

To install this module using the Module::Build method:

     perl Build.PL
     ./Build
     ./Build test
     ./Build install

## DEPENDENCIES

This module requires these other modules and libraries:

* Mojolicious

* Mojo::UserAgent::Role::Retry

COPYRIGHT AND LICENSE

Copyright (C) 2007-2017 by Bob Faist ( bob.faist at gmail.com )

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


