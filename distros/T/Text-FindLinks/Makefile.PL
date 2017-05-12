use inc::Module::Install;

# Metadata 
name         'Text-FindLinks';
perl_version '5.006';
all_from     'lib/Text/FindLinks.pm';

# Dependencies
requires      'Params::Validate' => 0;
test_requires 'Test::More' => '0';

WriteAll;
