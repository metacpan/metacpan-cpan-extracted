use inc::Module::Install 0.75;

all_from      'lib/WWW/ActiveState/PPM.pm';
requires      'LWP::Simple' => 0;
test_requires 'Test::More' => '0.42';
test_requires 'LWP::Online' => '1.07';

WriteAll;
