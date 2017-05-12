# $Id: Makefile.PL,v 1.19 2008/11/28 17:56:47 Martin Exp $

use inc::Module::Install;

all_from('lib/WWW/Search/AltaVista.pm');
version(2.154);

requires( perl => 5.004 );
requires('Date::Manip');
requires('HTML::TokeParser');
# requires('HTML::TreeBuilder');
test_requires('Test::More');
test_recommends('Test::Pod');
test_recommends('Test::Pod::Coverage');
# We need the verson which correctly handles "old" backends which have
# parse_tree() rather than the new _parse_tree():
requires('WWW::Search' => 2.561);
# We need the version with tm_run_test():
requires('WWW::Search::Test' => 2.263);
# We need the version with the fixed test_most_results():
requires('WWW::Search::Test' => 2.284);

WriteAll;

__END__
