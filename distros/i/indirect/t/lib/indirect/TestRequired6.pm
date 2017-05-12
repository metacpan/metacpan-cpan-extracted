package indirect::TestRequired6;

sub new { bless {} }

sub bar {
    my $foo = new indirect::TestRequired6;
}

sub baz {
    eval q{my $foo = new indirect::TestRequired6};
}

1;
