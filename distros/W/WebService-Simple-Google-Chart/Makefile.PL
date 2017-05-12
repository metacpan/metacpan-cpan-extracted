use strict;
use inc::Module::Install;
name 'WebService-Simple-Google-Chart';
all_from 'lib/WebService/Simple/Google/Chart.pm';

requires 'WebService::Simple' => "0.12";
build_requires 'Test::More';
build_requires 'Test::Pod';
build_requires 'Pod::Coverage';

use_test_base;
auto_include;
WriteAll;
