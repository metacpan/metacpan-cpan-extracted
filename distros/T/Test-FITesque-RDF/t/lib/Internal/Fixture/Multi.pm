package Internal::Fixture::Multi;
use 5.010001;
use strict;
use warnings;
use parent 'Test::FITesque::Fixture';
use Test::More ;

sub multiplication : Test : Plan(4) {
  my ($self, $args) = @_;
  note($args->{description});
  ok(defined($args->{factor1}), 'Factor 1 exists');
  ok(defined($args->{factor2}), 'Factor 2 exists');
  ok(defined($args->{product}), 'Product parameter exists');
  is($args->{factor1} * $args->{factor2}, $args->{product}, 'Product is correct');
}

1;
