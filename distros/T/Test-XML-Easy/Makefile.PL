use inc::Module::Install;

# Define metadata
name           'Test-XML-Easy';
all_from       'lib/Test/XML/Easy.pm';

requires       'XML::Easy'  => '0.002';

test_requires  'Test::More'  => '0';
test_requires  'Test::Builder::Tester' => '0';

license 'perl';

WriteAll;
