use strict;
use warnings;

=head1 NAME

75-plugin-nowarnings.t - testing Test::Group::NoWarnings

=cut

use Test::More tests => 1;
use Test::Group;
use Test::Group::Tester;


testscript_ok('#line '.(__LINE__+1)."\n".<<'EOSCRIPT', 2*4);
use strict;
use warnings;

use Test::More;
use Test::Group qw(test next_test_plugin);
use Test::Group::NoWarnings;

#
# Test each combination of subtests passing/failing and warning or not.
#

sub t1 ($&) {
    next_test_nowarnings();

    goto &test;
}

want_test('pass', 'nowarn_goodtests');
t1 nowarn_goodtests => sub {
    ok 1, "frist test passes";
    ok 1, "second test passes";
};

want_test('fail', 'nowarn_badtests',
    fail_diag("this test fails", 0, __LINE__+4),
    fail_diag("nowarn_badtests", 1, __LINE__+5),
);
t1 nowarn_badtests => sub {
    ok 0, "this test fails";
    ok 1, "second test passes";
};

want_test('fail', 'warn_goodtests',
    fail_diag("no warnings"),
    '# WARNING: [this is a warning]',
    '# WARNING: [this warning had no newline at '.
                                         __FILE__.' line '.(__LINE__+7).'.]',
    fail_diag("warn_goodtests", 1, __LINE__+7),
);
t1 warn_goodtests => sub {
    warn "this is a warning\n";
    ok 1, "first test passes";
    ok 1, "second test passes";
    warn "this warning had no newline";
};

want_test('fail', 'warn_badtests',
    fail_diag("this test fails", 0, __LINE__+10),
    fail_diag("no warnings"),
    '# WARNING: [this is a warning]',
    '# WARNING: [this warning had no newline at '.
                                         __FILE__.' line '.(__LINE__+7).'.]',
    fail_diag("warn_badtests", 1, __LINE__+7),
);
t1 warn_badtests => sub {
    warn "this is a warning\n";
    ok 1, "frist test ok";
    ok 0, "this test fails";
    warn "this warning had no newline";
};

#
# Repeat the tests using a plugin that runs the test group twice.
# The warn check should be innermost, so that check should be
# performed twice as well.
#

sub next_test_twice {
    next_test_plugin {
        my $next = shift;

        $next->();
        $next->();
    };
}

sub t2 ($&) {
    next_test_twice();
    next_test_nowarnings();

    goto &test;
}

want_test('pass', 'nowarn_goodtests');
t2 nowarn_goodtests => sub {
    ok 1, "frist test passes";
    ok 1, "second test passes";
};

want_test('fail', 'nowarn_badtests',
    fail_diag("this test fails", 0, __LINE__+5),
    fail_diag("this test fails", 0, __LINE__+4),
    fail_diag("nowarn_badtests", 1, __LINE__+5),
);
t2 nowarn_badtests => sub {
    ok 0, "this test fails";
    ok 1, "second test passes";
};

want_test('fail', 'warn_goodtests',
    fail_diag("no warnings"),
    '# WARNING: [this is a warning]',
    '# WARNING: [this warning had no newline at '.
                                        __FILE__.' line '.(__LINE__+11).'.]',
    fail_diag("no warnings"),
    '# WARNING: [this is a warning]',
    '# WARNING: [this warning had no newline at '.
                                         __FILE__.' line '.(__LINE__+7).'.]',
    fail_diag("warn_goodtests", 1, __LINE__+7),
);
t2 warn_goodtests => sub {
    warn "this is a warning\n";
    ok 1, "first test passes";
    ok 1, "second test passes";
    warn "this warning had no newline";
};

want_test('fail', 'warn_badtests',
    fail_diag("this test fails", 0, __LINE__+15),
    fail_diag("no warnings"),
    '# WARNING: [this is a warning]',
    '# WARNING: [this warning had no newline at '.
                                        __FILE__.' line '.(__LINE__+12).'.]',
    fail_diag("this test fails", 0, __LINE__+10),
    fail_diag("no warnings"),
    '# WARNING: [this is a warning]',
    '# WARNING: [this warning had no newline at '.
                                         __FILE__.' line '.(__LINE__+7).'.]',
    fail_diag("warn_badtests", 1, __LINE__+7),
);
t2 warn_badtests => sub {
    warn "this is a warning\n";
    ok 1, "frist test ok";
    ok 0, "this test fails";
    warn "this warning had no newline";
};

EOSCRIPT

