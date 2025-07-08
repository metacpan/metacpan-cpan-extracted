use strict;
use warnings;

use lib 't/lib';
use Test::Differences::TestUtils::Capture;

use Test::More;
use Test::Differences;

use Data::Dumper;
# same options at Test::Differences guts use
$Data::Dumper::Deparse   = 1;
$Data::Dumper::Indent    = 1;
$Data::Dumper::Purity    = 0;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Quotekeys = 0;
$Data::Dumper::Useperl   = 1;
$Data::Dumper::Sortkeys  = 0;

my $stderr = capture_error { system (
    $^X, (map { "-I$_" } (@INC)),
    qw(-Mstrict -Mwarnings -MTest::More -MTest::Differences),
    '-e', '
        END { done_testing(); }
        eq_or_diff(1, !!1);
    '
) };

# check both perl version and D::D version - while 5.38 comes with a compatible
# Data::Dumper, the user might have an older version installed if their app's
# deps pin to an older version
if($] >= 5.038000 && $Data::Dumper::VERSION >= 2.188) {
    ok(1 == !!1, "sanity check: 1 and !!1 are numerically the same on this perl");
    ok(''.1 == ''.(!!1), "sanity check: 1 and !!1 stringify the same on this perl");
    isnt(Dumper(1), Dumper(!!1), "sanity check: 1 and !!1 are Data::Dumper-ly different on this perl");
    is($stderr,
'#   Failed test at -e line 3.
# +---+-----+----------+
# | Ln|Got  |Expected  |
# +---+-----+----------+
# *  1|1    |!!1       *
# +---+-----+----------+
# Looks like you failed 1 test of 1.
',
    "spotted that 1 and !! are different");
} else {
    ok(1 == !!1, "sanity check: 1 and !!1 are numerically the same on this perl");
    ok(''.1 == ''.(!!1), "sanity check: 1 and !!1 stringify the same on this perl");
    is(Dumper(1), Dumper(!!1), "sanity check: 1 and !!1 are Data::Dumper-ly the same on this perl");
    is($stderr, '', "got no error output for a boolean true vs 1 on Ye Olde Perls");
    eq_or_diff(1, !!1, 'say that 1 and !!1 are the same');
}

done_testing;
