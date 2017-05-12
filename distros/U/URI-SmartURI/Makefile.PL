use inc::Module::Install 0.91;

name     'URI-SmartURI';
all_from 'lib/URI/SmartURI.pm';
author   'Rafael Kitover <rkitover@cpan.org>';

perl_version '5.008001';

requires 'URI' => '1.51';
requires 'Class::C3::Componentised';
requires 'File::Find::Rule';
requires 'List::Util';
requires 'List::MoreUtils';
requires 'Scalar::Util';
requires 'Moose';
requires 'namespace::clean';

build_requires 'Test::More', '0.94';;
build_requires 'Test::NoWarnings';
build_requires 'Test::Fatal';

auto_provides;
auto_install;

resources repository =>
    'git://github.com/rkitover/uri-smarturi.git';

WriteAll;
