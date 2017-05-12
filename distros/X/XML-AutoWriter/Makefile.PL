use inc::Module::Install;

perl_version '5.006001';
name 'XML-AutoWriter';
all_from 'lib/XML/AutoWriter.pm';

requires => 'XML::Parser';

build_requires => 'Test';
build_requires => 'IO::File';

auto_set_repository;
auto_manifest;
auto_install;
WriteAll;
