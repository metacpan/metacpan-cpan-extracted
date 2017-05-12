package ArraySlice;

sub foo {
    my @foo = qw( foo bar );
    my $last = $foo[-1];
    return $last;
}

1;
