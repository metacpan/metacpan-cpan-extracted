package Zing::Domain;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::Channel';

use Scalar::Util ();

our $VERSION = '0.27'; # VERSION

# ATTRIBUTES

has 'metadata' => (
  is => 'ro',
  isa => 'HashRef',
  new => 1,
);

fun new_metadata($self) {
  {}
}

has 'snapshots' => (
  is => 'ro',
  isa => 'Bool',
  def => 0,
);

# BUILDERS

fun BUILD($self) {
  if ($self->snapshots) {
    $self->{position} = $self->size;
    $self->{position}-- if $self->{position};
  }
  else {
    $self->reset;
    $self->state;
  }

  return !$self->isa('Zing::Lookup') ? $self->apply : $self;
}

# SHIMS

sub _copy {
  my ($data) = @_;

  if (!defined $data) {
    return undef;
  }
  elsif (ref $data eq 'ARRAY') {
    my $copy = [];
    for (my $i = 0; $i < @$data; $i++) {
      $copy->[$i] = _copy($data->[$i]);
    }
    return $copy;
  }
  elsif (ref $data eq 'HASH') {
    my $copy = {};
    for my $key (keys %$data) {
      $copy->{$key} = _copy($data->{$key});
    }
    return $copy;
  }
  else {
    return $data;
  }
}

sub _merge {
  my ($a_data, $b_data) = @_;

  return $a_data unless defined $b_data;

  for my $key (keys %$b_data) {
    my ($x, $y) = map { ref $_->{$key} eq 'HASH' } $b_data, $a_data;

    if ($x and $y) {
      $a_data->{$key} = _merge($a_data->{$key}, $b_data->{$key});
    }
    else {
      $a_data->{$key} = $b_data->{$key};
    }
  }

  return $a_data;
}

# METHODS

method apply() {
  undef $self->{state} if $self->renew;

  while (my $data = $self->recv) {
    my $op = $data->{op};
    my $key = $data->{key};
    my $val = $data->{value};

    if ((not defined $self->{state}) && %{$data->{snapshot}}) {
      $self->restore($data);
    }

    local $@;

    if ($op eq 'decr') {
      eval{($self->state->{$key} //= 0) -= ($val->[0] // 0)};
    }
    elsif ($op eq 'del') {
      eval{CORE::delete $self->state->{$key}};
    }
    elsif ($op eq 'incr') {
      eval{($self->state->{$key} //= 0 ) += ($val->[0] // 0)};
    }
    elsif ($op eq 'merge') {
      eval{_merge(($self->state->{$key} //= {}), $val->[0])};
    }
    elsif ($op eq 'pop') {
      eval{CORE::pop @{$self->state->{$key}}};
    }
    elsif ($op eq 'push') {
      eval{CORE::push @{$self->state->{$key}}, @$val};
    }
    elsif ($op eq 'set') {
      eval{$self->state->{$key} = $val->[0]};
    }
    elsif ($op eq 'shift') {
      eval{CORE::shift @{$self->state->{$key}}};
    }
    elsif ($op eq 'unshift') {
      eval{CORE::unshift @{$self->state->{$key}}, @$val};
    }

    if (%{$data->{metadata}}) {
      $self->{metadata} = _copy($data->{metadata});
    }

    $self->emit($key, $data);
  }

  return $self;
}

method change(Str $op, Str $key, Any @value) {
  my %fields = (
    key => $key,
    metadata => $self->metadata,
    snapshot => $self->snapshot,
    time => time,
    value => [@value],
  );

  if ($op eq 'decr') {
    $self->send({ %fields, op => 'decr' });
  }
  elsif ($op eq 'del') {
    $self->send({ %fields, op => 'del' });
  }
  elsif ($op eq 'incr') {
    $self->send({ %fields, op => 'incr' });
  }
  elsif ($op eq 'merge') {
    $self->send({ %fields, op => 'merge' });
  }
  elsif ($op eq 'pop') {
    $self->send({ %fields, op => 'pop' });
  }
  elsif ($op eq 'push') {
    $self->send({ %fields, op => 'push' });
  }
  elsif ($op eq 'set') {
    $self->send({ %fields, op => 'set' });
  }
  elsif ($op eq 'set') {
    $self->send({ %fields, op => 'set' });
  }
  elsif ($op eq 'shift') {
    $self->send({ %fields, op => 'shift' });
  }
  elsif ($op eq 'unshift') {
    $self->send({ %fields, op => 'unshift' });
  }

  return $self->apply;
}

method decr(Str $key, Int $value = 1) {
  return $self->apply->change('decr', $key, $value);
}

method del(Str $key) {
  return $self->apply->change('del', $key);
}

method emit(Str $key, HashRef $data) {
  my $handlers = $self->handlers->{$key};

  return $self if !$handlers;

  for my $handler (@$handlers) {
    $handler->[1]->($self, $data);
  }

  return $self;
}

method get(Str $key) {
  return $self->apply->state->{$key};
}

method handlers() {
  return $self->{handlers} ||= {};
}

method ignore(Str $key, Maybe[CodeRef] $sub) {
  return $self if !$self->handlers->{$key};

  return do { delete $self->handlers->{$key}; $self } if !$sub;

  my $ref = Scalar::Util::refaddr($sub);

  @{$self->handlers->{$key}} = grep {$ref ne $$_[0]} @{$self->handlers->{$key}};

  delete $self->handlers->{$key} if !@{$self->handlers->{$key}};

  return $self;
}

method incr(Str $key, Int $value = 1) {
  return $self->apply->change('incr', $key, $value);
}

method merge(Str $key, HashRef $value) {
  return $self->apply->change('merge', $key, $value);
}

method pop(Str $key) {
  return $self->apply->change('pop', $key);
}

method push(Str $key, Any @value) {
  return $self->apply->change('push', $key, @value);
}

method restore(HashRef $data) {
  return $self->{state} = _copy($data->{snapshot});
}

method set(Str $key, Any $value) {
  return $self->apply->change('set', $key, $value);
}

method shift(Str $key) {
  return $self->apply->change('shift', $key);
}

method snapshot() {
  return $self->snapshots ? _copy($self->state) : {};
}

method state() {
  return $self->{state} ||= {};
}

method listen(Str $key, CodeRef $sub) {
  my $ref = Scalar::Util::refaddr($sub);

  push @{$self->ignore($key, $sub)->handlers->{$key}}, [$ref, $sub];

  return $self;
}

method term() {
  return $self->app->term($self)->domain;
}

method unshift(Str $key, Any @value) {
  return $self->apply->change('unshift', $key, @value);
}

1;



=encoding utf8

=head1 NAME

Zing::Domain - Shared State Management

=cut

=head1 ABSTRACT

Shared State Management Construct

=cut

=head1 SYNOPSIS

  use Zing::Domain;

  my $domain = Zing::Domain->new(name => 'user-1');

  # $domain->recv;

=cut

=head1 DESCRIPTION

This package provides an aggregate abstraction and real-time cross-process
sharable data structure which offers many benefits, not least being able to see
a full history of state changes.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::Channel>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 metadata

  metadata(HashRef)

This attribute is read-only, accepts C<(HashRef)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 apply

  apply() : Object

The apply method receives events from the channel and applies the operations.

=over 4

=item apply example #1

  # given: synopsis

  $domain->apply;

=back

=cut

=head2 change

  change(Str $op, Str $key, Any @val) : Object

The change method commits an operation (and snapshot) to the channel. This
method is used internally and shouldn't need to be called directly.

=over 4

=item change example #1

  # given: synopsis

  $domain->change('incr', 'karma', 1);

=back

=cut

=head2 decr

  decr(Str $key, Int $val = 1) : Object

The decr method decrements the data associated with a specific key.

=over 4

=item decr example #1

  # given: synopsis

  $domain->decr('karma');

=back

=over 4

=item decr example #2

  # given: synopsis

  $domain->decr('karma', 2);

=back

=cut

=head2 del

  del(Str $key) : Object

The del method deletes the data associated with a specific key.

=over 4

=item del example #1

  # given: synopsis

  $domain->del('missing');

=back

=over 4

=item del example #2

  # given: synopsis

  $domain->set('email', 'me@example.com');

  $domain->del('email');

=back

=cut

=head2 emit

  emit(Str $key, HashRef $data) : Object

The emit method executes any callbacks registered using the L</listen> method
associated with a specific key.

=over 4

=item emit example #1

  # given: synopsis

  $domain->emit('email', { val => ['me@example.com'] });

=back

=over 4

=item emit example #2

  # given: synopsis

  $domain->listen('email', sub { my ($self, $data) = @_; $self->{event} = $data; });

  $domain->emit('email', { val => ['me@example.com'] });

=back

=cut

=head2 get

  get(Str $key) : Any

The get method return the data associated with a specific key.

=over 4

=item get example #1

  # given: synopsis

  $domain->get('email');

=back

=over 4

=item get example #2

  # given: synopsis

  $domain->set('email', 'me@example.com');

  $domain->get('email');

=back

=cut

=head2 ignore

  ignore(Str $key, Maybe[CodeRef] $sub) : Any

The ignore method removes the callback specified by the L</listen>, or all
callbacks associated with a specific key if no specific callback if provided.

=over 4

=item ignore example #1

  # given: synopsis

  $domain->ignore('email');

=back

=over 4

=item ignore example #2

  # given: synopsis

  my $callback = sub { my ($self, $data) = @_; $self->{event} = $data; };

  $domain->listen('email', $callback);

  $domain->ignore('email', $callback);

=back

=over 4

=item ignore example #3

  # given: synopsis

  my $callback_1 = sub { my ($self, $data) = @_; $self->{event} = [$data, 2]; };

  $domain->listen('email', $callback_1);

  my $callback_2 = sub { my ($self, $data) = @_; $self->{event} = [$data, 1]; };

  $domain->listen('email', $callback_2);

  $domain->ignore('email', $callback_1);

=back

=over 4

=item ignore example #4

  # given: synopsis

  my $callback_1 = sub { my ($self, $data) = @_; $self->{event} = [$data, 1]; };

  $domain->listen('email', $callback_1);

  my $callback_2 = sub { my ($self, $data) = @_; $self->{event} = [$data, 2]; };

  $domain->listen('email', $callback_2);

  $domain->ignore('email');

=back

=cut

=head2 incr

  incr(Str $key, Int $val = 1) : Object

The incr method increments the data associated with a specific key.

=over 4

=item incr example #1

  # given: synopsis

  $domain->incr('karma');

=back

=over 4

=item incr example #2

  # given: synopsis

  $domain->incr('karma', 5);

=back

=cut

=head2 listen

  listen(Str $key, CodeRef $sub) : Object

The listen method registers callbacks associated with a specific key which
will be invoked by the L</emit> method or whenever an event matching the key
specified is received and applied.

=over 4

=item listen example #1

  # given: synopsis

  $domain->ignore('email');

  $domain->listen('email', sub { my ($self, $data) = @_; $self->{event} = $data; });

=back

=over 4

=item listen example #2

  # given: synopsis

  $domain->ignore('email');

  my $callback = sub { my ($self, $data) = @_; $self->{event} = $data; };

  $domain->listen('email', $callback);

  $domain->listen('email', $callback);

=back

=over 4

=item listen example #3

  # given: synopsis

  $domain->ignore('email');

  my $callback_1 = sub { my ($self, $data) = @_; $self->{event} = [$data, 1]; };

  $domain->listen('email', $callback_1);

  my $callback_2 = sub { my ($self, $data) = @_; $self->{event} = [$data, 2]; };

  $domain->listen('email', $callback_2);

=back

=cut

=head2 merge

  merge(Str $key, HashRef $val) : Object

The merge method commits the data associated with a specific key to the channel
as a partial to be merged into any existing data.

=over 4

=item merge example #1

  # given: synopsis

  $domain->merge(data => { email => 'me@example.com', username => 'me' });

  $domain->merge(data => { email => 'we@example.com' });

=back

=over 4

=item merge example #2

  # given: synopsis

  $domain->set(data => { username => 'we' });

  $domain->merge(data => { email => 'me@example.com', username => 'me' });

  $domain->merge(data => { email => 'we@example.com' });

=back

=over 4

=item merge example #3

  # given: synopsis

  $domain->set(data => { username => 'we', colors => ['white'] });

  $domain->merge(data => { email => 'me@example.com', username => 'me' });

  $domain->merge(data => { email => 'we@example.com' });

  $domain->merge(data => { colors => ['white', 'green'], username => 'we' });

=back

=cut

=head2 pop

  pop(Str $key) : Object

The pop method pops the data off of the stack associated with a specific key.

=over 4

=item pop example #1

  # given: synopsis

  $domain->pop('history');

=back

=cut

=head2 push

  push(Str $key, Any @val) : Object

The push method pushes data onto the stack associated with a specific key.

=over 4

=item push example #1

  # given: synopsis

  $domain->push('history', { updated => 1234567890 });

=back

=cut

=head2 set

  set(Str $key, Any $val) : Object

The set method commits the data associated with a specific key to the channel.

=over 4

=item set example #1

  # given: synopsis

  $domain->set('updated', 1234567890);

=back

=cut

=head2 shift

  shift(Str $key) : Object

The shift method shifts data off of the stack associated with a specific key.

=over 4

=item shift example #1

  # given: synopsis

  $domain->shift('history');

=back

=cut

=head2 state

  state() : HashRef

The state method returns the raw aggregate data associated with the object.

=over 4

=item state example #1

  # given: synopsis

  $domain->state;

=back

=cut

=head2 unshift

  unshift(Str $key, Any @val) : Object

The unshift method unshifts data onto the stack associated with a specific key.

=over 4

=item unshift example #1

  # given: synopsis

  $domain->unshift('history', { updated => 1234567890 });

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/cpanery/zing/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/cpanery/zing/wiki>

L<Project|https://github.com/cpanery/zing>

L<Initiatives|https://github.com/cpanery/zing/projects>

L<Milestones|https://github.com/cpanery/zing/milestones>

L<Contributing|https://github.com/cpanery/zing/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/cpanery/zing/issues>

=cut
