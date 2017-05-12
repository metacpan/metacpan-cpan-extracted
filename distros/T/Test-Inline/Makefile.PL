use inc::Module::Install 1.00;

all_from       'lib/Test/Inline.pm';
requires_from  'lib/Test/Inline.pm';
requires       'Getopt::Long'     => '2.34';
requires       'File::Find::Rule' => '0.26';
requires       'File::chmod'      => '0.31';
requires       'File::Remove'     => '0.37';
requires       'Config::Tiny'     => '2.00';
requires       'File::Flat'       => '1.00';
test_requires  'Test::More'       => '0.42';
test_requires  'Test::Script'     => '1.02';
test_requires  'Test::ClassAPI'   => '1.02';
install_script 'inline2test';

# Because some programs incorrectly do things like...
#
#   if ( installed('Test::Inline') ) { system('pod2test') }
#
# ... we need to make sure the legacy stuff it is installed.
requires       'Pod::Tests'            => '0.18';

WriteAll;
