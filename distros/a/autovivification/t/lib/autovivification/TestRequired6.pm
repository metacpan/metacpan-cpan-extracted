package autovivification::TestRequired6;

sub new { bless {} }

sub bar {
 exists $main::blurp->{bar};
}

sub baz {
 eval q[exists $main::blurp->{baz}];
}

1;
