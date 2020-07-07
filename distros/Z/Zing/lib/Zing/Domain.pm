package Zing::Domain;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

use Zing::Channel;

our $VERSION = '0.12'; # VERSION

# ATTRIBUTES

has 'name' => (
  is => 'ro',
  isa => 'Str',
  req => 1,
);

has 'channel' => (
  is => 'ro',
  isa => 'Channel',
  new => 1,
);

fun new_channel($self) {
  Zing::Channel->new(name => $self->name)
}

# BUILDERS

fun BUILD($self) {
  $self->channel->{cursor}-- if $self->channel->{cursor};

  return $self->apply;
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

# METHODS

method apply() {
  undef $self->{state} if $self->channel->renew;

  while (my $data = $self->recv) {
    my $op = $data->{op};
    my $key = $data->{key};
    my $val = $data->{val};

    if ($data->{snapshot} && !$self->{state}) {
      $self->{state} = _copy($data->{snapshot});
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
  }

  return $self;
}

method change(Str $op, Str $key, Any @val) {
  my %fields = (
    key => $key,
    snapshot => _copy($self->state),
    time => time,
    val => [@val],
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

method get(Str $key) {
  return $self->apply->state->{$key};
}

method decr(Str $key, Int $val = 1) {
  return $self->apply->change('decr', $key, $val);
}

method del(Str $key) {
  return $self->apply->change('del', $key);
}

method incr(Str $key, Int $val = 1) {
  return $self->apply->change('incr', $key, $val);
}

method pop(Str $key) {
  return $self->apply->change('pop', $key);
}

method push(Str $key, Any @val) {
  return $self->apply->change('push', $key, @val);
}

method recv() {
  return $self->channel->recv;
}

method send(HashRef $data) {
  return $self->channel->send($data);
}

method set(Str $key, Any $val) {
  return $self->apply->change('set', $key, $val);
}

method shift(Str $key) {
  return $self->apply->change('shift', $key);
}

method state() {
  return $self->{state} ||= {};
}

method unshift(Str $key, Any @val) {
  return $self->apply->change('unshift', $key, @val);
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

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 channel

  channel(Channel)

This attribute is read-only, accepts C<(Channel)> values, and is optional.

=cut

=head2 name

  name(Str)

This attribute is read-only, accepts C<(Str)> values, and is required.

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
file"|https://github.com/iamalnewkirk/zing/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/zing/wiki>

L<Project|https://github.com/iamalnewkirk/zing>

L<Initiatives|https://github.com/iamalnewkirk/zing/projects>

L<Milestones|https://github.com/iamalnewkirk/zing/milestones>

L<Contributing|https://github.com/iamalnewkirk/zing/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/zing/issues>

=cut
