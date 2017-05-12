use inc::Module::Install;

name     'XML-Declare';
all_from 'lib/XML/Declare.pm';
license  'perl';

build_requires 'Test::More';
build_requires 'Test::NoWarnings';
build_requires 'lib::abs',  '0.90';

requires 'XML::LibXML', '1.70';
requires 'Scalar::Util';

auto_provides;
auto_install;

WriteAll;

my $MI  = $Module::Install::MAIN;
print STDERR "Generated makefile for ".$MI->load('name')->name."-".$MI->load('version')->version."\n";
