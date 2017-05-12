use strict;
use warnings;

=head1 NAME

56-wrappers.t - wrapping test(), checking that line numbers in failed
test diagnostics come out right.

=cut

use Test::More tests => 4;
use Test::Group::Tester;

# Try various combinations of using $Test::Builder::Level and
# $Test::Group::Level.

foreach my $level_var_1 (qw(Group Builder)) {
    foreach my $level_var_2 (qw(Group Builder)) {
        testscript_ok('#line '.(__LINE__+1)."\n".<<EOSCRIPT, 3);
use strict;
use warnings;

use Test::Group;
use Test::More;

sub test2 (\$&) {
    my (\$name, \$code) = \@_;

    local \$Test::$level_var_1\::Level = \$Test::$level_var_1\::Level + 1;
    &test(\$name, \$code);
}

sub test3 (\$&) {
    my (\$name, \$code) = \@_;

    local \$Test::$level_var_2\::Level = \$Test::$level_var_2\::Level + 1;
    &test2(\$name, \$code);
}

want_test('fail', 'msg_testouter',
    fail_diag('msg_testinner', 0, __LINE__+4),
    fail_diag('msg_testouter', 1, __LINE__+4),
);    
test msg_testouter => sub {
    ok 0, "msg_testinner";
};

want_test('fail', 'msg_test2outer',
    fail_diag('msg_test2inner', 0, __LINE__+4),
    fail_diag('msg_test2outer', 1, __LINE__+4),
);
test2 msg_test2outer => sub {
    ok 0, "msg_test2inner";
};

want_test('fail', 'msg_test3outer',
    fail_diag('msg_test3inner', 0, __LINE__+4),
    fail_diag('msg_test3outer', 1, __LINE__+4),
);
test3 msg_test3outer => sub {
    ok 0, "msg_test3inner";
};

EOSCRIPT
    }
}
