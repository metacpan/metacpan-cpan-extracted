package Foo_T;
use strict;
use Test::Usage;
use Foo;

example('t1', sub {
    my $f = Foo->new();
    my $exp = 1;
    my $got = $f->get_val();
    ok(
        $got == $exp,
        "Expected get_val() to be $exp for a new Foo object.",
        "But got $got."
    );
});

example('t2', sub {
    test_mul(1,  6,  2,  3);
    test_mul(2,  0,  2,  0);
    test_mul(3,  3, -2, -1.5);
        # This one should fail, as the test is flawed (-6 instead of 6
        # fixes it).
    test_mul(4,  6, -2,  3);
});

sub test_mul {
    my ($label, $exp, $mul1, $mul2) = @_;
    my $f = Foo->new();
    $f->mul_val($mul1);
    $f->mul_val($mul2);
    my $got = $f->get_val();
    ok_labeled(
        $label,
        $got == $exp,
        "get_val() should return $exp after calling mul_val() "
          . "with $mul1 then $mul2.",
        "But got $got."
    );
}

1;

