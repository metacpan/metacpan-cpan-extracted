package Buddha::CheckFixture;

use strict;
use warnings;

use base qw(Test::FITesque::Fixture);

my $fake_runtime = 0;

sub existing {
  $fake_runtime = 1;
  return "I exist";
}

sub non_existing {
  return "foo";
}

sub parse_method_string {
  my ($self, $method_string) = @_;
  (my $method_name = $method_string) =~ s/\s+/_/g;

  return undef if $fake_runtime;

  my $coderef = $self->can($method_name);
  return $coderef;
}

1;
