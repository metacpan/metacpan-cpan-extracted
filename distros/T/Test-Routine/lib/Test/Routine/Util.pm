use strict;
use warnings;
package Test::Routine::Util;
# ABSTRACT: helpful exports for dealing with test routines
$Test::Routine::Util::VERSION = '0.029';
#pod =head1 OVERVIEW
#pod
#pod Test::Routine::Util is documented in L<the Test::Routine docs on running
#pod tests|Test::Routine/Running Tests>.  Please consult those for more information.
#pod
#pod Both C<run_tests> and C<run_me> are simple wrappers around the process of
#pod composing given Test::Routine roles into a class and instance using
#pod L<Test::Routine::Compositor>, creating a L<Test::Routine::Runner> object and
#pod telling it to execute the tests on the test instance.
#pod
#pod =cut

use Scalar::Util qw(reftype);

use Sub::Exporter::Util qw(curry_method);
use Test::Routine::Compositor;
use Test::Routine::Runner ();

use Sub::Exporter -setup => {
  exports => [
    run_tests => \'_curry_tester',
    run_me    => \'_curry_tester',
  ],
  groups => [ default => [ qw(run_me run_tests) ] ],
};

our $UPLEVEL = 0;

sub _curry_tester {
  my ($class, $name, $arg) = @_;

  Carp::confess("the $name generator does not accept any arguments")
    if keys %$arg;

  return sub {
    local $UPLEVEL = $UPLEVEL + 1;
    $class->$name(@_);
  };
}

sub run_me {
  my ($class, $desc, $arg) = @_;

  if (@_ == 2 and (reftype $desc || '') eq 'HASH') {
    ($desc, $arg) = (undef, $desc);
  }

  my $caller = caller($UPLEVEL);

  local $UPLEVEL = $UPLEVEL + 1;
  $class->run_tests($desc, $caller, $arg);
}

sub _runner_class     { 'Test::Routine::Runner' }
sub _compositor_class { 'Test::Routine::Compositor' }

sub run_tests {
  my ($class, $desc, $inv, $arg) = @_;

  my @caller = caller($UPLEVEL);

  $desc = defined($desc)
        ? $desc
        : sprintf 'tests from %s, line %s', $caller[1], $caller[2];

  my $builder = $class->_compositor_class->instance_builder($inv, $arg);

  my $self = $class->_runner_class->new({
    description   => $desc,
    instance_from => $builder,
  });

  $self->run;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Routine::Util - helpful exports for dealing with test routines

=head1 VERSION

version 0.029

=head1 OVERVIEW

Test::Routine::Util is documented in L<the Test::Routine docs on running
tests|Test::Routine/Running Tests>.  Please consult those for more information.

Both C<run_tests> and C<run_me> are simple wrappers around the process of
composing given Test::Routine roles into a class and instance using
L<Test::Routine::Compositor>, creating a L<Test::Routine::Runner> object and
telling it to execute the tests on the test instance.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
