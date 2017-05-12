use inc::Module::Install;
name 'WWW-Mechanize-DecodedContent';
all_from 'lib/WWW/Mechanize/DecodedContent.pm';

requires 'WWW::Mechanize';
requires 'HTTP::Response::Encoding';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
