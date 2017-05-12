use Test::More 0.89;

local $SIG{__WARN__} = sub { fail("Got unexpected warning"); diag($_[0]) };

if ($] >= 5.010) {
    is (eval <<'END', 1, 'say compiles') or diag $@;
    use 5.010;
    no experimentals;
    my $x = 1;
    say q{} if $x == 0;
    1;
END
}

if ($] >= 5.018 && $] < 5.025002) {
    is (eval <<'END', undef, "lexical subs don't compile") or diag $@;
    no experimentals;
    my sub foo { 1 };
    is(foo(), 1, "lexical subs work as expected");
    1;
END
}

if ($] >= 5.021005) {
    is (eval <<'END', undef, "ref aliasing doesn't compile") or diag $@;
    no experimentals;
    \@a = \@b;
    is(\@a, \@b, 'ref aliasing works as expected');
    1;
END
}

done_testing;


