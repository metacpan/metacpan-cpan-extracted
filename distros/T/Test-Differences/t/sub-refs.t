use strict;
use warnings;

use lib 't/lib';
use Test::Differences::TestUtils::Capture;

use Test::More;
use Test::Differences;

my $stderr = capture_error { system (
    $^X, (map { "-I$_" } (@INC)),
    qw(-Mstrict -Mwarnings -MTest::More -MTest::Differences),
    '-e', '
        END { done_testing(); }
        eq_or_diff(sub{1}, sub{2})
    '
) };
ok(
    $stderr eq  # perl 5.16 onwards
'#   Failed test at -e line 4.
# +----+-------------------+-------------------+
# | Elt|Got                |Expected           |
# +----+-------------------+-------------------+
# |   0|sub {              |sub {              |
# |   1|    use warnings;  |    use warnings;  |
# |   2|    use strict;    |    use strict;    |
# *   3|    1;             |    2;             *
# |   4|}                  |}                  |
# +----+-------------------+-------------------+
# Looks like you failed 1 test of 1.
' ||
    $stderr eq # perl 5.8 to 5.14
q{#   Failed test at -e line 4.
# +----+------------------------+------------------------+
# | Elt|Got                     |Expected                |
# +----+------------------------+------------------------+
# |   0|sub {                   |sub {                   |
# |   1|    use warnings;       |    use warnings;       |
# |   2|    use strict 'refs';  |    use strict 'refs';  |
# *   3|    1;                  |    2;                  *
# |   4|}                       |}                       |
# +----+------------------------+------------------------+
# Looks like you failed 1 test of 1.
},
    "got expected error output for different sub-refs"
);

$Test::Differences::NoDeparse = 1;
eq_or_diff sub { 1 }, sub { 2 }, "different sub-refs ignored when NoDeparse turned on";

done_testing;
