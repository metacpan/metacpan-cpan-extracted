use strict;
use warnings;
use Test::More tests => 1;
use Test::Skip::UnlessExistsExecutable;

skip_all_unless_exists '/bin/sh';
skip_all_unless_exists 'perl';

ok 1;
