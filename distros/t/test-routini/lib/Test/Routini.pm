package Test::Routini;

use 5.008001;
use Test::More;
use base 'Exporter';
our @EXPORT = qw(test run_me run_test);

#expose the test cache for testing purposes only
our $test_cache;
our $VERSION = 0.1;


sub test {
  my $name = shift;
  my $code = pop;

  $test_cache->{$name} = $code;
};

sub run_me {
  my $class = scalar(caller);
  my $instance = $class->new();
  my $tests_run = 0;
  foreach my $test_name (keys %$test_cache) {
    $instance->run_test($test_name, $test_cache->{$test_name});
    $tests_run++;
  }
  ok $tests_run > 0, 'tests run';
};

sub run_test {
  my ($self, $name, $code) = @_;

  Test::More::subtest($name, sub { &{$code}($self) });
}

=pod

=head1 NAME

Test::Routini - A simple test framework primarialy for Moo/Mouse/Moose which provides a slice of the functionality of Test::Routine without the complexity of Moose

=head1 SYNOPSIS

  use Moo;
  use Test::More;

  use Test::Routini;

  has foo => ( is => 'rw', default => sub { 'bar' } );

  test "bob test" => sub {
      my $self = shift;
      print "running test\n";
      ok 1;
      is $self->foo, 'bar';
  };

  before run_test => sub {
      print "running before each test!\n";
  };

  run_me;
  done_testing;
  1;

=head1 DESCRIPTION

This module provides enough of the Test::Routine look and feel to make nice tests without the need for a MOP

=head1 AUTHOR

Aaron Moses E<lt>zebardy@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2013 Aaron Moses.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
