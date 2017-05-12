use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/macro.pm';
readme_from 'lib/macro.pm';

requires 'PPI'                  => 1.205;

requires 'Filter::Util::Call'   => 1.06;

test_requires 'Test::Warn' => 0.11;

author_tests 'xt';

auto_set_repository;

clean_files q{macro-* example/*.plc misc/*.plc};

WriteAll check_nmake => 0;
