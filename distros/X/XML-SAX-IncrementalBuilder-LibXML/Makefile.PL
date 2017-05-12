use inc::Module::Install;

name		'XML-SAX-IncrementalBuilder-LibXML';
all_from	'lib/XML/SAX/IncrementalBuilder/LibXML.pm';

requires	'XML::LibXML'		=> '1.66';
requires	'Class::InsideOut'	=> '0';

test_requires	'Test::More'	=> '0';
author_tests('t/author');

auto_provides;

WriteAll;

