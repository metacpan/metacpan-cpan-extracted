use inc::Module::Install;

name 'Test-XML-Element';
all_from 'lib/Test/XML/Element.pm';

requires 'Test::Builder';
requires 'XML::Simple';

test_requires 'Test::More';

auto_install;
WriteAll;

