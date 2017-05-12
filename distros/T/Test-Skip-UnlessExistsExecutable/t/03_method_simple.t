use strict;
use warnings;
use Test::More tests => 10;
use Test::Skip::UnlessExistsExecutable;

skip_all_unless_exists '/usr/bin/notfound';

fail 'do not reach here';
