#!perl -T

use strict;
use warnings;

BEGIN { delete $ENV{PERL_TEST_LEANER_USES_TEST_MORE} }

use Test::Leaner tests => 1;

note <<'NOTE';
a very
  long
   comment printed as a # note

not ok 2 - only in a note
NOTE

pass <<'PASS';
a very
  long
   comment printed as a # pass

not ok 3 - only in a comment
PASS

diag <<'DIAG';
a very
  long
   comment printed as a # diagnostic

not ok 4 - testing TAP in comments, disregard that
DIAG
