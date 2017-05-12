
# $Id: Makefile.PL,v 1.6 2008/02/01 02:50:02 Daddy Exp $

use inc::Module::Install;

name('WWW-Search-Backends');
version_from('lib/WWW/Search/Backends.pm');
author('Martin Thurn <mthurn@cpan.org>');
abstract('Query web search engines and get URLs');
license('perl');
requires(perl => 5.004);

requires('Data::Dumper');
build_requires('ExtUtils::testlib');
requires('HTML::Parse');
requires('HTML::TreeBuilder');
build_requires('Test::More');
build_recommends('Test::Pod');
requires('URI');
requires('WWW::Search');
# We need the function WWW::Search::Test::tm_run_test_no_approx():
requires('WWW::Search::Test' => 2.271);

WriteAll;

__END__
