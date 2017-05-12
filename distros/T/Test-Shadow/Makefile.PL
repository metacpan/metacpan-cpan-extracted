use strict;
use warnings;
use inc::Module::Install;

name        'Test-Shadow';
all_from    'lib/Test/Shadow.pm';

license     'perl';
author      'osfameron';

requires 'Test::More';
requires 'Test::Deep';

test_requires 'Test::Fatal';
test_requires 'Test::Tester';

auto_install;
WriteAll;
