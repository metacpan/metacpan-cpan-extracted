package main;

use strict;
use warnings;

# local $^W = 0;

use Test::More 0.88;	# for done_testing.

use lib qw{ inc };

use My::Module::Test;

require_ok 'Win32API::File::Time'
    or BAIL_OUT;

can_ok 'Win32API::File::Time', qw{ GetFileTime SetFileTime utime }
    or BAIL_OUT;

done_testing;

1;

# ex: set textwidth=72 :
