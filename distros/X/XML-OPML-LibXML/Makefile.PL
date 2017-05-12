use inc::Module::Install;
name 'XML-OPML-LibXML';
all_from 'lib/XML/OPML/LibXML.pm';
requires 'XML::LibXML', 1.60;

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
