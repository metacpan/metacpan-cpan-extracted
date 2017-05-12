use inc::Module::Install;

name('XML-Liberal');
all_from('lib/XML/Liberal.pm');
auto_set_repository;

requires('Carp');
requires('Class::Accessor');
requires('Encode');
requires('Encode::Guess');
requires('HTML::Entities');
requires('HTML::Tagset');
requires('List::Util');
requires('Module::Pluggable::Fast', 0.16);
requires('UNIVERSAL::require');
requires('XML::LibXML', '1.69_02');

build_requires('Test::More');
use_test_base;

auto_include;
WriteAll;
