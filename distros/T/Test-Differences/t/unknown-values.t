#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::Differences::TestUtils::Capture;

use Test::More;

eval { require Unknown::Values } || plan skip_all => 'Unknown::Values is needed for these tests';

my $stderr = capture_error { system(
    $^X, (map { "-I$_" } (@INC)), 't/script/unknown-values'
) };

my @expected_failures = (
'#   Failed test at t/script/unknown-values line 13.
# +----+------------------------------------------------------------+-----------------------------------------------------------------+
# | Elt|Got                                                         |Expected                                                         |
# +----+------------------------------------------------------------+-----------------------------------------------------------------+
# *   0|got something containing an Unknown::Values::unknown value  |expected something containing an Unknown::Values::unknown value  *
# +----+------------------------------------------------------------+-----------------------------------------------------------------+
', '#   Failed test at t/script/unknown-values line 14.
# +----+------------------------------------------------------------+----------+
# | Elt|Got                                                         |Expected  |
# +----+------------------------------------------------------------+----------+
# *   0|got something containing an Unknown::Values::unknown value  |undef\n   *
# +----+------------------------------------------------------------+----------+
', '#   Failed test at t/script/unknown-values line 16.
# +----+------------------------------------------------------------+-----------------------------------------------------------------+
# | Elt|Got                                                         |Expected                                                         |
# +----+------------------------------------------------------------+-----------------------------------------------------------------+
# *   0|got something containing an Unknown::Values::unknown value  |expected something containing an Unknown::Values::unknown value  *
# +----+------------------------------------------------------------+-----------------------------------------------------------------+
', '#   Failed test at t/script/unknown-values line 17.
# +----+------------------------------------------------------------+----+----------+
# | Elt|Got                                                         | Elt|Expected  |
# +----+------------------------------------------------------------+----+----------+
# *   0|got something containing an Unknown::Values::unknown value  *   0|[\n       *
# |    |                                                            *   1|  1,      *
# |    |                                                            *   2|  undef   *
# |    |                                                            *   3|]         *
# +----+------------------------------------------------------------+----+----------+
# Looks like you failed 4 tests of 4.
'
);
# We might get extra whitespace under 'make test' compared to running 'perl -Ilib t/...'
if($stderr =~ /\n\n/) {
    is($stderr, join("\n", @expected_failures), 'got expected errors');
} else {
    is($stderr, join("", @expected_failures), 'got expected errors');
}

done_testing;
