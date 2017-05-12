# $Id: Makefile.PL,v 1.6 2008/07/26 19:09:45 Martin Exp $

use inc::Module::Install;

all_from('lib/WWW/Search/Search.pm');
author('Martin Thurn <mthurn@cpan.org>');

requires('perl' => 5.004);
requires('Carp');
requires('URI::Escape');
requires('WWW::SearchResult' => 2.078);
build_requires('Test::More');

WriteAll;

1;

__END__

