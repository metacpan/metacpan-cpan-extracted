# -*- perl -*-
# test that auto save only happens when enabled

use Test::More tests => 1;
use warnings;
use strict;

ok ! -f 'test.db', 'check that no file got written when autosave disabled';
