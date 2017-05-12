use inc::Module::Install 1.00;

name           'pip';
all_from       'lib/pip.pm';
requires       'Carp'           => 0;
requires       'File::Basename' => 0;

# On Windows we need the rel2abs volume fixes
requires       'File::Spec'     => win32() ? '3.23' : '0.80';

# On Windows we need the "chmod on delete" fix
# This also lets pip package properly on 5.8.5 (specifically RHEL 4)
requires       'File::Temp'     => win32() ? '0.15' : '0.14';

requires       'File::Which'    => '1.08';
requires       'File::pushd'    => '0.32';
requires       'Getopt::Long'   => 0;
requires       'CPAN'           => '1.76';
requires       'CPAN::Inject'   => win32() ? '0.11' : '0.07';
requires       'Params::Util'   => '1.00';
requires       'URI'            => 0;
requires       'LWP::Simple'    => 0;
requires       'PAR::Dist'      => '0.25';
test_requires  'Test::More'     => '0.42';
test_requires  'Test::Script'   => '1.02';
test_requires  'LWP::Online'    => '1.06';
install_script 'pip';

# Required for p5z creation and extraction
requires       'IO::Zlib'       => 0;
requires       'Archive::Tar'   => 0;

# Required for zip support
requires       'Archive::Zip'   => '1.29';

WriteAll;
