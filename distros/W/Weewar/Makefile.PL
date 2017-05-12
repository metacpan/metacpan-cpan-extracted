use inc::Module::Install;

name('Weewar');
all_from('lib/Weewar.pm');

requires 'XML::LibXML';
requires 'LWP::UserAgent';
requires 'Class::Accessor';
requires 'DateTime::Format::RSS';
requires 'DateTime';
requires 'Readonly';

build_requires 'Test::More';
build_requires 'ok';
build_requires 'Test::TableDriven';
WriteAll();
