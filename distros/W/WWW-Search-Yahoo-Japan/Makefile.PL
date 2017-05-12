
# $Id: Makefile.PL,v 1.6 2008/12/25 18:55:08 Martin Exp $

use inc::Module::Install;

all_from('lib/WWW/Search/Yahoo/Japan.pm');
version(2.103);

requires( perl => '5.004' );
requires('Data::Dumper');
build_requires('Test::More');
# We need the version that has method names with underscores:
requires('WWW::Search::Yahoo' => 2.377);
# We need the version of WWW::Search::Test that exports its tm_
# functions:
build_requires('WWW::Search::Test' => 2.265);

WriteAll;

__END__
