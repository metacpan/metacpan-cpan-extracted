use inc::Module::Install;

all_from	'lib/XML/Generator/XMPP.pm';
perl_version    '5.006';


requires        'XML::SAX::Base'                        => '0';
requires	'XML::LibXML::XPathContext'		=> '1.63';
requires	'XML::SAX::IncrementalBuilder::LibXML'	=> '0.02';

test_requires	'Test::More'	=> '0';

author_tests('t/author');

auto_provides;

WriteAll;

