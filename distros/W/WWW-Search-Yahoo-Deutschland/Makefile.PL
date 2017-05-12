
# $Id: Makefile.PL,v 1.3 2008/03/05 04:56:45 Daddy Exp $

use inc::Module::Install;

name('WWW-Search-Yahoo-Deutschland');
all_from('lib/WWW/Search/Yahoo/Deutschland.pm');
author(q{Martin 'Kingpin' Thurn <mthurn@cpan.org>});
license('perl');

requires('WWW::Search::Yahoo');
build_requires('Test::More');

WriteAll;

__END__

