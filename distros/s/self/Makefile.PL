use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/self.pm';

requires
    'PadWalker' => '1.93',
    'Devel::Declare' => '0.003004',
    'B::OPCheck' => '0.27',
    'B::Hooks::Parser' => '0.08',
    'Sub::Exporter'     => '0';

build_requires  'Test::More'        => '0.42';

tests 't/*.t';
author_tests 'xt';

WriteAll;


