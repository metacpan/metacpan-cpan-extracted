package Venus::Role::Unacceptable;

use 5.018;

use strict;
use warnings;

use Venus::Role 'raise';

# BUILDERS

sub BUILD {
  my ($self) = @_;

  my $class = ref $self || $self;
  my %attrs = map +($_, $_), $self->META->attrs;
  my @unknowns = sort grep !exists($attrs{$_}), keys %$self;

  raise 'Venus::Role::Unacceptable::Error', {
    name => 'on.build',
    '$stash' => {unknowns => [@unknowns]},
    message => "$class was passed unknown attribute(s): " . join ', ',
      map "'$_'", @unknowns,
  }
  if @unknowns;

  return $self;
}

1;



=head1 NAME

Venus::Role::Unacceptable - Unacceptable Role

=cut

=head1 ABSTRACT

Unacceptable Role for Perl 5

=cut

=head1 SYNOPSIS

  package ExampleAccept;

  use Venus::Class 'attr';

  attr 'name';

  package ExampleDeny;

  use Venus::Class 'attr', 'with';

  with 'Venus::Role::Unacceptable';

  attr 'name';

  package main;

  my $example = ExampleDeny->new(name => 'example', test => 12345);

  # Exception! (isa Venus::Role::Unacceptable::Error)

=cut

=head1 DESCRIPTION

This package provides a mechanism for raising an exception when unexpected
constructor arguments are encountered.

=cut