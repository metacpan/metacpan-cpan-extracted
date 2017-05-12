use strict;
use warnings;

use Test::More qw(no_plan);
use Test::Requires::Env;

test_environments( 'UNKNOWN_ENVIRONMENT' );
fail 'Do not reach here';

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# coding: utf-8-unix
# End:
#
# vim: expandtab shiftwidth=4:
