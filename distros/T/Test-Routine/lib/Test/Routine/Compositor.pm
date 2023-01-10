use v5.12.0;
use warnings;
package Test::Routine::Compositor 0.030;
# ABSTRACT: the tool for turning test routines into runnable classes

use Carp qw(confess);
use Class::Load;
use Moose::Meta::Class;
use Params::Util qw(_CLASS);
use Scalar::Util qw(blessed);

use namespace::clean;

sub _invocant_for {
  my ($self, $thing, $arg) = @_;

  confess "can't supply preconstructed object for running tests"
    if $arg and blessed $thing;

  return $thing if blessed $thing;

  $arg //= {};
  my $new_class = $self->_class_for($thing);
  $new_class->name->new($arg);
}

sub _class_for {
  my ($class, $inv) = @_;

  confess "can't supply preconstructed object for test class construction"
    if blessed $inv;

  $inv = [ $inv ] if _CLASS($inv);

  my @bases;
  my @roles;

  for my $item (@$inv) {
    Class::Load::load_class($item);
    my $target = $item->meta->isa('Moose::Meta::Class') ? \@bases
               : $item->meta->isa('Moose::Meta::Role')  ? \@roles
               : confess "can't run tests for this weird thing: $item";

    push @$target, $item;
  }

  confess "can't build a test class from multiple base classes" if @bases > 1;
  @bases = 'Moose::Object' unless @bases;

  my $new_class = Moose::Meta::Class->create_anon_class(
    superclasses => \@bases,
    cache        => 1,
    (@roles ? (roles => \@roles) : ()),
  );

  return $new_class->name;
}

sub instance_builder {
  my ($class, $inv, $arg) = @_;

  confess "can't supply preconstructed object and constructor arguments"
    if $arg and blessed $inv;

  return sub { $inv } if blessed $inv;

  my $new_class = $class->_class_for($inv);
  $arg //= {};

  return sub { $new_class->new($arg); };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Routine::Compositor - the tool for turning test routines into runnable classes

=head1 VERSION

version 0.030

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
