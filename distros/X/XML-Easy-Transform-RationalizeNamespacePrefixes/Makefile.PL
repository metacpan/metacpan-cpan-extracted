use inc::Module::Install;

# Define metadata
name           'XML-Easy-Transform-RationalizeNamespacePrefixes';
all_from       'lib/XML/Easy/Transform/RationalizeNamespacePrefixes.pm';

requires       'XML::Easy'  => '0.002';
requires       'Carp::Clan' => '0';
test_requires  'Test::More' => '0';
test_requires  'Test::XML::Easy' => '0';

license 'perl';

WriteAll;
