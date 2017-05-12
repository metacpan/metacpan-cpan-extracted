use 5.008006;
use strict;
use warnings;
use inc::Module::Install;

name 'Weather-TW';
all_from 'lib/Weather/TW.pm';

requires 'DateTime' => 0.70;
requires 'LWP::UserAgent' => 0;
requires 'LWP::Simple' => 6.00;
requires 'Moose' => 2.04;
requires 'HTML::TreeBuilder' => 0;
requires 'HTML::Element' => 0;
requires 'XML::Smart' => 0;
requires 'Carp' => 0;
requires 'JSON' => 0;
requires 'YAML' => 0;

test_requires 'Test::More' => 0;
test_requires 'Test::More::UTF8' => 0;

author 'dryman <idryman@gmail.com>';
license 'mit';
readme_markdown_from 'lib/Weather/TW.pm';

WriteAll;
