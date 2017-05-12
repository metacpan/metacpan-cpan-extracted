package indirect::TestRequired3X;

sub new { push @main::new, __PACKAGE__ }

no indirect hook => \&main::cb3;

new indirect::TestRequired3X;
