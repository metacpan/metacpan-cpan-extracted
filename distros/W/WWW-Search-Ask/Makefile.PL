
# $Id: Makefile.PL,v 1.7 2008/11/30 01:38:44 Martin Exp $

use inc::Module::Install;

all_from('lib/WWW/Search/Ask.pm');

requires('perl' => 5.004);
requires('Carp');
test_requires('Test::More');
test_recommends('Test::Pod');
test_recommends('Test::Pod::Coverage');
requires('WWW::Search');
# We need the version that has 'unlike':
test_requires('WWW::Search::Test' => 2.287);

WriteAll;

__END__
