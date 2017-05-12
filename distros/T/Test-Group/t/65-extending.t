use strict;
use warnings;

=head1 NAME

65-extending.t - checks for code snippets in Test::Group::Extending

=cut

use Test::More tests => 5;
use Test::Group;
use Test::Group::Tester;
use File::Slurp;

my $filename = $INC{"Test/Group.pm"};
$filename =~ s{\.pm$}{/Extending.pod};
my $source = read_file $filename;

sub get_snippet_extending {
    my $name = shift;

    my ($snip) = ($source =~
                  m/=for tests "$name" begin(.*)=for tests "$name" end/s);
    die "Did not find snippet $name" if (! defined $snip);
    return $snip;
}

my $snip = get_snippet_extending("maybe_test");
testscript_ok("$snip\n#line ".(__LINE__+1)."\n".<<'EOSCRIPT', 6, "maybe_test");

use Test::More;

# passing test, no ONLY_TEST
want_test('pass', 'maybetest_outer');
maybe_test maybetest_outer  => sub {
    ok 1, "maybetest_inner";
};

# failing test, no ONLY_TEST
want_test('fail', 'maybetest_outer',
    fail_diag('maybetest_inner', 0, __LINE__+4),
    fail_diag('maybetest_outer', 1, __LINE__+4),
);
maybe_test maybetest_outer  => sub {
    ok 0, "maybetest_inner";
};

$ENV{ONLY_TEST} = "foo,maybetest_outer,bar";

# passing test, ONLY_TEST includes
want_test('pass', 'maybetest_outer');
maybe_test maybetest_outer  => sub {
    ok 1, "maybetest_inner";
};

# failing test, ONLY_TEST includes
want_test('fail', 'maybetest_outer',
    fail_diag('maybetest_inner', 0, __LINE__+4),
    fail_diag('maybetest_outer', 1, __LINE__+4),
);
maybe_test maybetest_outer  => sub {
    ok 0, "maybetest_inner";
};

$ENV{ONLY_TEST} = "foo,bar";

# passing test, ONLY_TEST excludes
want_test('skip', 'maybetest_outer not enabled');
maybe_test maybetest_outer  => sub {
    ok 1, "maybetest_inner";
};

# failing test, ONLY_TEST excludes
want_test('skip', 'maybetest_outer not enabled');
maybe_test maybetest_outer  => sub {
    ok 0, "maybetest_inner";
};

EOSCRIPT

##########################################################################

my $snip2 = get_snippet_extending("timed_test");
eval 'use Time::HiRes';
if ($@) {
    $snip2 =~ s/use Time::HiRes;//;
    $snip2 =~ s/Time::HiRes::time\(\)/ "93287499.24234" /g;
}
testscript_ok("$snip2\n#line ".(__LINE__+1)."\n".<<'EOSCRIPT', 2, "timed_test");

use Test::More;

want_test('pass', 'timed_pass_outer',
    qr/timed_pass_outer start: \d+/,
    qr/timed_pass_outer done:  \d+/,
);
timed_test timed_pass_outer => sub {
    ok 1, 'timed_pass_inner';
};

want_test('fail', 'timed_fail_outer',
    qr/timed_fail_outer start: \d+/,
    fail_diag('timed_fail_inner', 0, __LINE__+5),
    fail_diag('timed_fail_outer', 1, __LINE__+5),
    qr/timed_fail_outer done:  \d+/,
);
timed_test timed_fail_outer => sub {
    ok 0, 'timed_fail_inner';
};

EOSCRIPT

##########################################################################

my $snip3 = get_snippet_extending("next_test_nopathchange");
testscript_ok("$snip3\n#line ".(__LINE__+1)."\n".<<'EOSCRIPT', 4, "nopathc");

use Test::More;

next_test_nopathchange();
want_test('pass', 'pass_nomess_outer');
test pass_nomess_outer => sub {
    ok 1, 'pass_nomess_inner';
};

next_test_nopathchange();
want_test('fail', 'fail_nomess_outer',
    fail_diag('fail_nomess_inner', 0, __LINE__+4),
    fail_diag('fail_nomess_outer', 1, __LINE__+4),
);
test fail_nomess_outer => sub {
    ok 0, 'fail_nomess_inner';
};

next_test_nopathchange();
want_test('fail', 'mess_nomess_outer',
    fail_diag('path not modified', 0),
    qr/^#\s*got:.*foo/,
    qr/^#\s*expected:/,
    fail_diag('mess_nomess_outer', 1, __LINE__+5),
);
test mess_nomess_outer => sub {
    ok 1, 'mess_nomess_inner';
    $ENV{PATH} .= ":foo";
};

next_test_nopathchange();
want_test('fail', 'failmess_nomess_outer',
    fail_diag('failmess_nomess_inner', 0, __LINE__+7),
    fail_diag('path not modified', 0),
    qr/^#\s*got:.*foo/,
    qr/^#\s*expected:/,
    fail_diag('failmess_nomess_outer', 1, __LINE__+5),
);
test failmess_nomess_outer => sub {
    ok 0, 'failmess_nomess_inner';
    $ENV{PATH} .= ":foo";
};
EOSCRIPT

##########################################################################

my $snip4 = get_snippet_extending("next_test_with_and_without_debug");
testscript_ok("$snip4\n#line ".(__LINE__+1)."\n".<<'EOSCRIPT', 3, "wwdebug");

use Test::More;

delete $ENV{DEBUG};

want_test('pass', 'passboth_debug_outer');
next_test_with_and_without_debug();
test passboth_debug_outer => sub {
    ok 1, 'passboth_debug_inner';
};

want_test('fail', 'failboth_debug_outer',
    fail_diag('failboth_debug_inner', 0, __LINE__+6),
    fail_diag('failboth_debug_inner', 0, __LINE__+5),
    fail_diag('failboth_debug_outer', 1, __LINE__+5),
);
next_test_with_and_without_debug();
test failboth_debug_outer => sub {
    ok 0, 'failboth_debug_inner';
};

want_test('fail', 'failone_debug_outer',
    fail_diag('failone_debug_inner', 0, __LINE__+5),
    fail_diag('failone_debug_outer', 1, __LINE__+5),
);
next_test_with_and_without_debug();
test failone_debug_outer => sub {
    ok $ENV{DEBUG}, 'failone_debug_inner';
};

EOSCRIPT

##########################################################################

my $snip5 = $snip3 . $snip4 . get_snippet_extending("mytest");
$snip5 =~ s/mytest foo =>.*//s;
testscript_ok("$snip5\n#line ".(__LINE__+1)."\n".<<'EOSCRIPT', 2, "mytest");

use Test::More;

local $ENV{PATH} = $ENV{PATH} . ":bar";

want_test('pass', 'allpass_outer');
mytest allpass_outer => sub {
    ok 1, 'allpass_inner';
};

want_test('fail', 'allfail_outer',
    fail_diag('allfail_inner', 0, __LINE__+11),
    fail_diag('path not modified', 0),
    qr/^#\s*got:.*:bar:foo\W*$/,
    qr/^#\s*expected:.*:bar\W*$/,
    fail_diag('allfail_inner', 0, __LINE__+7),
    fail_diag('path not modified', 0),
    qr/^#\s*got:.*:bar:foo:foo\W*$/,
    qr/^#\s*expected:.*:bar:foo\W*$/,
    fail_diag('allfail_outer', 1, __LINE__+5),
);
mytest allfail_outer => sub {
    ok 0, 'allfail_inner';
    $ENV{PATH} .= ":foo";
};

EOSCRIPT

