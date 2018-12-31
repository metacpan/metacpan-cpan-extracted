#
# $Id$
#

use strict;
use warnings;

use Test::More;
eval "use Test::NoBreakpoints 0.10";
plan skip_all => "Test::NoBreakpoints 0.10 required for testing" if $@;
plan 'no_plan';
all_files_no_breakpoints_ok();

#
# EOF
