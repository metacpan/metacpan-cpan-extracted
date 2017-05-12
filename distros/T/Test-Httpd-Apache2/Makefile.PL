use strict;
use inc::Module::Install;

name 'Test-Httpd-Apache2';
all_from 'lib/Test/Httpd/Apache2.pm';
readme_from 'lib/Test/Httpd/Apache2.pm';

requires 'Class::Accessor::Lite';
requires 'Test::TCP';
test_requires 'LWP::Simple';
test_requires 'Test::More' => 0.88; # done_testing()

WriteAll;
