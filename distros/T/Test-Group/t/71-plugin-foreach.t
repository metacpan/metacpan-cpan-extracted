use strict;
use warnings;

=head1 NAME

71-plugin-foreach.t - testing plugin interface, with a plugin that repeats
the test group for several values of something.

=cut

use Test::More tests => 1;
use Test::Group::Tester;

testscript_ok('#line '.(__LINE__+2).<<'EOSCRIPT', 8);

use strict;
use warnings;

use Test::More;
use Test::Group qw(:DEFAULT next_test_plugin);

sub next_test_foreach (\$@) {
    my ($varref, @values) = @_;

    next_test_plugin {
        my $next = shift;

        foreach my $value (@values) {
            $$varref = $value;
            $next->();
        }
    };
}

my ($x, $p, $q);

next_test_foreach $x, 17;
want_test('pass', 'onevalue_pass');
test onevalue_pass => sub { ok $x==17, "[$x] is 17" };


next_test_foreach $x, 18;
want_test('fail', 'onevalue_fail',
    fail_diag("[18] is 17", 0,__LINE__+3),
    fail_diag("onevalue_fail", 1, __LINE__+2),
);
test onevalue_fail => sub { ok $x==17, "[$x] is 17" };


next_test_foreach $x, 18, 19;
want_test('pass', 'twovalue_pass');
test twovalue_pass => sub { ok $x>17, "[$x] > 17" };


next_test_foreach $x, 11, 12;
want_test('fail', 'twovalue_fail',
    fail_diag("[11] > 17", 0, __LINE__+4),
    fail_diag("[12] > 17", 0, __LINE__+3),
    fail_diag("twovalue_fail", 1, __LINE__+2),
);
test twovalue_fail => sub { ok $x>17, "[$x] > 17" };


my $count = 0;
want_test('pass', 'plugins gone now');
test 'plugins gone now' => sub { ok 1 ; ++$count };
want_test('pass', 'no carry over');
is $count, 1, "no carry over";


next_test_foreach $p, 1, 2;
next_test_foreach $q, 3, 4;
want_test('pass', "twotwo_pass");
test twotwo_pass => sub { ok $p+$q < 10, "$p + $q < 10" };


next_test_foreach $p, 1, 2;
next_test_foreach $q, 3, 4;
want_test('fail', "twotwo_fail",
    fail_diag("1 + 3 > 10", 0, __LINE__+6),
    fail_diag("1 + 4 > 10", 0, __LINE__+5),
    fail_diag("2 + 3 > 10", 0, __LINE__+4),
    fail_diag("2 + 4 > 10", 0, __LINE__+3),
    fail_diag("twotwo_fail", 1, __LINE__+2),
);
test twotwo_fail => sub { ok $p+$q > 10, "$p + $q > 10" };

EOSCRIPT

