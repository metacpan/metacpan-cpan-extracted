package autovivification::TestRequired1;

my $x = $main::blurp->{r1_main}->{vivify};

eval 'my $y = $main::blurp->{r1_eval}->{vivify}';

1;
