# -*- perl -*-

# Test the tabulate fuction.

use 5;
use warnings;
use strict;

use Test::More tests => 1;

@ARGV = qw(-g | t/script.data);
require_ok 'bin/tabulate';

#| diff - t/script.out && echo ok 1

