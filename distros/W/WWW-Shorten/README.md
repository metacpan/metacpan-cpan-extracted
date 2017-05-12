# NAME

WWW::Shorten - Perl Interface to services to shorten URLs
[![Build Status](https://travis-ci.org/p5-shorten/www-shorten.svg?branch=master)](https://travis-ci.org/p5-shorten/www-shorten)

# SYNOPSIS

```perl
#!/usr/bin/env perl
use strict;
use warnings;

use WWW::Shorten 'TinyURL'; # Recommended
# use WWW::Shorten 'Linkz'; # or one of the others
# use WWW::Shorten 'Shorl';

# Individual modules have have their own syntactic variations.
# See the documentation for the particular module you intend to use for details

my $url = 'https://metacpan.org/pod/WWW::Shorten';
my $short_url = makeashorterlink($url);
my $long_url  = makealongerlink($short_url);


# - OR -
# If you don't like the long function names:

use WWW::Shorten 'TinyURL', ':short';
my $short_url = short_link($url);
my $long_url = long_link( $short_url );
```

# DESCRIPTION

A Perl interface to various services that shorten URLs. These sites maintain
databases of long URLs, each of which has a unique identifier.

# DEPRECATION NOTICE

The following shorten services have been deprecated as the endpoints no longer
exist or function:

- WWW::Shorten::LinkToolbot
- WWW::Shorten::Linkz
- WWW::Shorten::MakeAShorterLink
- WWW::Shorten::Metamark
- WWW::Shorten::TinyClick
- WWW::Shorten::Tinylink
- WWW::Shorten::Qurl
- WWW::Shorten::Qwer

When version 3.100 is released, these deprecated services will not be part of
the distribution.

# COMMAND LINE PROGRAM

A very simple program called `shorten` is supplied in the
distribution's `bin` folder. This program takes a URL and
gives you a shortened version of it.

# ISSUES OR CONTRIBUTIONS

Please submit any [issues](https://github.com/p5-shorten/www-shorten/issues) you
might have.  We appreciate all help, suggestions, noted problems, and especially patches.

Note that support for extra shortening services should be released as separate modules, like [WWW::Shorten::Googl](https://metacpan.org/pod/WWW::Shorten::Googl) or [WWW::Shorten::Bitly](https://metacpan.org/pod/WWW::Shorten::Bitly).

Support for this module is supplied primarily via the using the
[GitHub Issues](https://github.com/p5-shorten/www-shorten/issues) but we also
happily respond to issues submitted to the
[CPAN RT](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Shorten) system via the web
or email: &lt;bug-www-shorten@rt.cpan.org>

* https://github.com/p5-shorten/www-shorten/issues
* http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Shorten
* ( shorter URL: http://xrl.us/rfb )
* bug-www-shorten@rt.cpan.org

# AUTHOR

Iain Truskett spoon@cpan.org

# CONTRIBUTORS

- Alex Page -- for the original LWP hacking on which Dave based his code.
- Ask Bjoern Hansen -- providing [WWW::Shorten::Metamark](https://metacpan.org/pod/WWW::Shorten::Metamark)
- Chase Whitener capoeirab@cpan.org
- Dave Cross dave@perlhacks.com -- Authored WWW::MakeAShorterLink on which this was based
- Eric Hammond -- writing [WWW::Shorten::NotLong](https://metacpan.org/pod/WWW::Shorten::NotLong)
- Jon and William (wjr) -- smlnk services
- Kazuhiro Osawa yappo@cpan.org
- Kevin Gilbertson (Gilby) -- TinyURL API information
- Martin Thurn -- bug fixes
- Matt Felsen (mattf) -- shorter function names
- Neil Bowers neilb@cpan.org
- PJ Goodwin -- code for [WWW::Shorten::OneShortLink](https://metacpan.org/pod/WWW::Shorten::OneShortLink)
- Shashank Tripathi shank@shank.com -- for providing [WWW::Shorten::SnipURL](https://metacpan.org/pod/WWW::Shorten::SnipURL)
- Simon Batistoni -- giving the `makealongerlink` idea to Dave.
- Everyone else we might have missed.

In 2004 Dave Cross took over the maintenance of this distribution
following the death of Iain Truskett.

In 2016, Chase Whitener took over the maintenance of this distribution.

# LICENCE AND COPYRIGHT

Copyright (c) 2002 by Iain Truskett.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

# SEE ALSO

- [CGI::Shorten](https://metacpan.org/pod/CGI::Shorten)
- [WWW::Shorten::Simple](https://metacpan.org/pod/WWW::Shorten::Simple)
