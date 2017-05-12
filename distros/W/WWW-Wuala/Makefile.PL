use inc::Module::Install;

# Define metadata
name 'WWW-Wuala';
all_from 'lib/WWW/Wuala.pm';

requires 'LWP::Simple' => 5.810;
requires 'File::Temp'      => 0.18;

test_requires 'Test::More'     => 0;
test_requires 'Test::Exception'     => 0;

homepage 'http://virii.lu';

author 'Perforin <perforin@cpan.org>';

auto_install;

WriteAll;