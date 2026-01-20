package Venus::Role::Fromable;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Role 'fault';

# METHODS

sub from {
  my ($self, @args) = @_;

  require Venus::What;

  my $type = lc scalar Venus::What->new(value => $args[0])->identify;

  (my $name, @args) = @args < 2 ? ($type, @args) : (@args);

  my $class = ref $self || $self;

  fault "No name provided to \"from\" via package \"$class\"" if !$name;

  my $method = "from_$name";

  return $class->new($class->$method(@args)) if $class->can($method);

  fault "Unable to locate class method \"$method\" via package \"$class\"";
}

# EXPORTS

sub EXPORT {
  ['from']
}

1;



=head1 NAME

Venus::Role::Fromable - Fromable Role

=cut

=head1 ABSTRACT

Fromable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Person;

  use Venus::Class 'attr', 'with';

  with 'Venus::Role::Fromable';

  attr 'fname';
  attr 'lname';

  sub from_name {
    my ($self, $name) = @_;

    my ($fname, $lname) = split / /, $name;

    return {
      fname => $fname,
      lname => $lname,
    };
  }

  package main;

  my $person = Person->from(name => 'Elliot Alderson');

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'Person')

=cut

=head1 DESCRIPTION

This package modifies the consuming package and provides methods for
dispatching to constructor argument builders.

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 from

  from(any @values) (object)

The from method takes a key and value(s) and dispatches to the corresponding
argument builder named in the form of C<from_${name}> which should return
arguments required by the constructor. The constructor will be called with the
arguments returned from the argument builder and a class instance will be
returned. If the key is omitted, the data type of the first value will be used
as the key (or name), i.e. if the daya type of the first value is a string this
method will attempt to dispatch to a builder named C<from_string>.

I<Since C<4.15>>

=over 4

=item from example 1

  # given: synopsis;

  $person = Person->from(name => 'Elliot Alderson');

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'Person')

  # $person->fname;

  # "Elliot"

  # $person->lname;

  # "Alderson"

=back

=over 4

=item from example 2

  # given: synopsis;

  $person = Person->from('', 'Elliot Alderson');

  # Exception! "No name provided to \"from\" via package \"Person\""

=back

=over 4

=item from example 3

  # given: synopsis;

  $person = Person->from(undef, 'Elliot Alderson');

  # Exception! "No name provided to \"from\" via package \"Person\""

=back

=over 4

=item from example 4

  # given: synopsis;

  $person = Person->from('fullname', 'Elliot Alderson');

  # Exception! "Unable to locate class method \"from_fullname\" via package \"Person\""

=back

=over 4

=item from example 5

  # given: synopsis;

  $person = Person->from('Elliot Alderson');

  # Exception! "Unable to locate class method \"from_string\" via package \"Person\""

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2022, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut