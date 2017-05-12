use strict;
use inc::Module::Install;
name 'Text-CSV_PP-Simple';
all_from 'lib/Text/CSV_PP/Simple.pm';

requires 'Text::CSV_PP';

build_requires 'Test::More';
use_test_base;
auto_install;
WriteAll;
