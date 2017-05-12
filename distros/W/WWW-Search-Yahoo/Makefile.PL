
use inc::Module::Install;

all_from('lib/WWW/Search/Yahoo.pm');

version(2.415);

requires( perl => '5.004' );
requires('Data::Dumper');
requires('Date::Manip');
build_requires('Encode');
requires('HTML::TreeBuilder');
build_requires('I18N::Charset');
# Test::More is needed for `make test`:
build_requires('Test::More');
requires('URI');
requires('URI::Escape');
# We need the version of WWW::Search that has the new underscore-named _methods:
requires('WWW::Search' => 2.557);
# We need the version of WWW::Search::Test that exports its tm_
# functions:
build_requires('WWW::Search::Test' => 2.265);

WriteAll;

__END__
