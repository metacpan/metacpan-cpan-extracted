use strict;
use warnings;
use inc::Module::Install;

name 'Text-Greeking-zh_TW';

all_from 'lib/Text/Greeking/zh_TW.pm';
requires_from 'lib/Text/Greeking/zh_TW.pm';

build_requires  'Test::More'        => '0.42';

tests 't/*.t';
author_tests 'xt/*.t';

WriteAll;
