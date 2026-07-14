use strict;
use warnings;
use Test::Synopsis;
use Test::More tests => 2;

# GH #20: a =for test_synopsis directive must be applied to the SYNOPSIS
# code regardless of whether it appears before or after the code block.
# Before the fix, a =for placed AFTER the code block was collected too
# late and never applied, so this compile check failed with
# "Global symbol '$assa' requires explicit package name".

synopsis_ok("t/lib/TestForBeforeCode.pm");
synopsis_ok("t/lib/TestForAfterCode.pm");
