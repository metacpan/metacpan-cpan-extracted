use inc::Module::Install;

name     'Test-WWW-Declare';
all_from 'lib/Test/WWW/Declare.pm';

build_requires 'Test::Tester' => '0.107';
build_requires 'HTTP::Server::Simple' => '0.35';

# Work around Test::Builder's complaint about the need to preload Test::Tester.
$INC{'Test/Tester.pm'} = __FILE__;

requires 'Test::More';
requires 'Test::Builder';
requires 'Test::WWW::Mechanize';

WriteAll;

