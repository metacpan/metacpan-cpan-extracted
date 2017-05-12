use inc::Module::Install;
name 'Web-oEmbed';
all_from 'lib/Web/oEmbed.pm';

requires 'Any::Moose';
requires 'LWP';
requires 'XML::LibXML::Simple';
requires 'JSON::XS';
requires 'HTML::Element';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
