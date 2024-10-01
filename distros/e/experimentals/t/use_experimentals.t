use Test::More 0.89;

local $SIG{__WARN__} = sub { fail("Got unexpected warning"); diag($_[0]) };

if ($] >= 5.010000) {
    if ($] <= 5.023000) {
        is (eval <<'END', 1, 'lexical topic compiles') or diag $@;
        use experimentals;
        my $_ = 1;
        is($_, 1, 'lexical topic works as expected');
        1;
END
    }
}
else {
    fail("No experimental features available on perl $]");
}

if ($] >= 5.010000) {
    if ($] <= 5.023000) {
        is (eval <<'END', 1, 'lexical topic compiles') or diag $@;
        use experimentals;
        my $_ = 1;
        is($_, 1, 'lexical topic works as expected');
        1;
END
    }
}
else {
    fail("No experimental features available on perl $]");
}

if ($] >= 5.010001 && $] <= 5.040) {
    is (eval <<'END', 1, 'switch compiles') or diag $@;
    use experimentals;
    sub bar { 1 };
    given(1) {
        when (\&bar) {
            pass("switch works as expected");
        }
        default {
            fail("switch works as expected");
        }
    }
    1;
END
}

if ($] >= 5.010001) {
    local $SIG{__WARN__} = sub { if ($] < 5.037) { fail("Got unexpected warning"); diag($_[0]) } };
    if ($] <= 5.040000) {
        is (eval <<'END', 1, 'smartmatch compiles') or diag $@;
        use experimentals;
        sub bar { 1 };
        is(1 ~~ \&bar, 1, "smartmatch works as expected");
        1;
END
    }
}

if ($] >= 5.018) {
    is (eval <<'END', 1, 'lexical subs compiles') or diag $@;
    use experimentals;
    my sub foo { 1 };
    is(foo(), 1, "lexical subs work as expected");
    1;
END
}

if ($] >= 5.021005) {
    is (eval <<'END', 1, 'ref aliasing compiles') or diag $@;
    use experimentals;
    \@a = \@b;
    is(\@a, \@b, 'ref aliasing works as expected');
    1;
END
}

done_testing;

