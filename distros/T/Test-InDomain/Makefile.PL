use inc::Module::Install;

name     'Test-InDomain';
all_from 'lib/Test/InDomain.pm';
author   q{Laurent Dami <dami@cpan.org>};
license  'perl';
requires 'Data::Domain'          => '1.02';
requires 'Scalar::Does'          => '0.007';
requires 'Test::Builder::Module' => 0;

build_requires 'Test::More';

auto_install;

WriteAll;

