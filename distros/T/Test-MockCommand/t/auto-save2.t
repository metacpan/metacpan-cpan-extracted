# -*- perl -*-
# test that auto save actually happens

use Test::More tests => 1;
use warnings;
use strict;

ok -f 'test.db', 'check that auto-save actually wrote a file';
