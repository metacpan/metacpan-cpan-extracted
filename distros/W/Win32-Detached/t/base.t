use strict;
use warnings;

package base_test;

use Test::Most;

use lib '../lib';

@ARGV = qw( --no_detach );

use_ok("Win32::Detached");

done_testing;
