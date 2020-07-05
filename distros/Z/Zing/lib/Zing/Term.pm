package Zing::Term;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

use Zing::Node;
use Zing::Server;

use Carp ();
use Scalar::Util ();

use overload '""' => 'string';

our $VERSION = '0.10'; # VERSION

# ATTRIBUTES

has 'facets' => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  opt => 1,
);

has 'handle' => (
  is => 'ro',
  isa => 'Str',
  req => 1,
);

has 'symbol' => (
  is => 'ro',
  isa => 'Str',
  req => 1,
);

has 'bucket' => (
  is => 'ro',
  isa => 'Str',
  req => 1,
);

has 'system' => (
  is => 'ro',
  isa => 'Str',
  req => 1,
);

has 'target' => (
  is => 'ro',
  isa => 'Str',
  req => 1,
);

# BUILDERS

state $symbols = {
  'Zing::Channel'  => 'channel',
  'Zing::Data'     => 'data',
  'Zing::Domain'   => 'domain',
  'Zing::Kernel'   => 'kernel',
  'Zing::KeyVal'   => 'keyval',
  'Zing::Mailbox'  => 'mailbox',
  'Zing::Process'  => 'process',
  'Zing::PubSub'   => 'pubsub',
  'Zing::Queue'    => 'queue',
  'Zing::Registry' => 'registry',
  'Zing::Repo'     => 'repo',
};

fun BUILDARGS($self, $item, @data) {
  my $args = {};

  if (Scalar::Util::blessed($item)) {
    my $local = sprintf 'local(%s)', Zing::Server->new->name;

    @data = map {s/[^a-zA-Z0-9-\$\.]/-/g; lc} map {split /:/} @data;

    if ($item->isa('Zing::Channel')) {
      $args->{symbol} = $symbols->{'Zing::Channel'};
      $args->{target} = $item->target eq 'global' ? 'global' : $local;
      $args->{bucket} = $item->name;
      $args->{facets} = [@data];
    }
    elsif ($item->isa('Zing::Data')) {
      my ($bucket, @facets) = split /:/, $item->name;
      $args->{symbol} = $symbols->{'Zing::Data'};
      $args->{target} = $local;
      $args->{bucket} = $bucket;
      $args->{facets} = [@facets, @data];
    }
    elsif ($item->isa('Zing::Domain')) {
      $args->{symbol} = $symbols->{'Zing::Domain'};
      $args->{target} = $item->channel->target eq 'global' ? 'global' : $local;
      $args->{bucket} = $item->name;
      $args->{facets} = [@data];
    }
    elsif ($item->isa('Zing::Kernel')) {
      my ($bucket, @facets) = split /:/, $item->name;
      $args->{symbol} = $symbols->{'Zing::Kernel'};
      $args->{target} = $local;
      $args->{bucket} = $bucket;
      $args->{facets} = [@facets, @data];
    }
    elsif ($item->isa('Zing::Mailbox')) {
      my ($bucket, @facets) = split /:/, $item->name;
      $args->{symbol} = $symbols->{'Zing::Mailbox'};
      $args->{target} = 'global';
      $args->{bucket} = $bucket;
      $args->{facets} = [@facets, @data];
    }
    elsif ($item->isa('Zing::Process')) {
      my ($bucket, @facets) = split /:/, $item->name;
      $args->{symbol} = $symbols->{'Zing::Process'};
      $args->{target} = $local;
      $args->{bucket} = $bucket;
      $args->{facets} = [@facets, @data];
    }
    elsif ($item->isa('Zing::Queue')) {
      $args->{symbol} = $symbols->{'Zing::Queue'};
      $args->{target} = $item->target eq 'global' ? 'global' : $local;
      $args->{bucket} = $item->name;
      $args->{facets} = [@data];
    }
    elsif ($item->isa('Zing::Registry')) {
      $args->{symbol} = $symbols->{'Zing::Registry'};
      $args->{target} = $item->target eq 'global' ? 'global' : $local;
      $args->{bucket} = $item->name;
      $args->{facets} = [@data];
    }
    elsif ($item->isa('Zing::KeyVal')) {
      $args->{symbol} = $symbols->{'Zing::KeyVal'};
      $args->{target} = $item->target eq 'global' ? 'global' : $local;
      $args->{bucket} = $item->name;
      $args->{facets} = [@data];
    }
    elsif ($item->isa('Zing::PubSub')) {
      $args->{symbol} = $symbols->{'Zing::PubSub'};
      $args->{target} = $item->target eq 'global' ? 'global' : $local;
      $args->{bucket} = $item->name;
      $args->{facets} = [@data];
    }
    elsif ($item->isa('Zing::Repo')) {
      $args->{symbol} = $symbols->{'Zing::Repo'};
      $args->{target} = $item->target eq 'global' ? 'global' : $local;
      $args->{bucket} = $item->name;
      $args->{facets} = [@data];
    }
    else {
      Carp::confess qq(Error in term: Unrecognizable "object");
    }
    $args->{handle} = $ENV{ZING_NS} || 'main';
    $args->{system} = 'zing';
  }
  elsif(defined $item && !ref $item) {
    my $schema = [split /:/, "$item", 6];

    my $system = $schema->[0];
    my $handle = $schema->[1];
    my $target = $schema->[2];
    my $symbol = $schema->[3];
    my $bucket = $schema->[4];
    my $extras = $schema->[5];

    my $facets = [split /:/, $extras || ''];

    unless ($system eq 'zing') {
      Carp::confess qq(Error in term: Unrecognizable "system" in: $item);
    }
    unless ($target =~ m{^(global|local\(\d+\.\d+\.\d+\.\d+\))$}) {
      Carp::confess qq(Error in term: Unrecognizable "target" ($target) in: $item);
    }
    unless (grep {$_ eq $symbol} values %$symbols) {
      Carp::confess qq(Error in term: Unrecognizable "symbol" ($symbol) in: $item);
    }

    $args->{system} = $system;
    $args->{handle} = $handle;
    $args->{target} = $target;
    $args->{symbol} = $symbol;
    $args->{bucket} = $bucket;
    $args->{facets} = $facets;
  }
  else {
    Carp::confess 'Unrecognizable Zing term provided';
  }

  return $args;
}

# METHODS

method channel() {
  unless ($self->symbol eq 'channel') {
    Carp::confess 'Error in term: not a "channel"';
  }

  return $self->string;
}

method data() {
  unless ($self->symbol eq 'data') {
    Carp::confess 'Error in term: not a "data" term';
  }

  return $self->string;
}

method domain() {
  unless ($self->symbol eq 'domain') {
    Carp::confess 'Error in term: not a "domain" term';
  }

  return $self->string;
}

method kernel() {
  unless ($self->symbol eq 'kernel') {
    Carp::confess 'Error in term: not a "kernel" term';
  }

  return $self->string;
}

method keyval() {
  unless ($self->symbol eq 'keyval') {
    Carp::confess 'Error in term: not a "keyval" term';
  }

  return $self->string;
}

method mailbox() {
  unless ($self->symbol eq 'mailbox') {
    Carp::confess 'Error in term: not a "mailbox" term';
  }

  return $self->string;
}

method process() {
  unless ($self->symbol eq 'process') {
    Carp::confess 'Error in term: not a "process" term';
  }

  return $self->string;
}

method pubsub() {
  unless ($self->symbol eq 'pubsub') {
    Carp::confess 'Error in term: not a "pubsub" term';
  }

  return $self->string;
}

method queue() {
  unless ($self->symbol eq 'queue') {
    Carp::confess 'Error in term: not a "queue" term';
  }

  return $self->string;
}

method registry() {
  unless ($self->symbol eq 'registry') {
    Carp::confess 'Error in term: not a "registry" term';
  }

  return $self->string;
}

method repo() {
  unless ($self->symbol eq 'repo') {
    Carp::confess 'Error in term: not a "repo" term';
  }

  return $self->string;
}

method string() {
  my $system = $self->system;
  my $handle = $self->handle;
  my $target = $self->target;
  my $symbol = $self->symbol;
  my $bucket = $self->bucket;
  my $facets = $self->facets || [];

  return lc join ':', $system, $handle, $target, $symbol, $bucket, @$facets;
}

1;

=encoding utf8

=head1 NAME

Zing::Term - Resource Representation

=cut

=head1 ABSTRACT

Resource Representation

=cut

=head1 SYNOPSIS

  use Zing::KeyVal;
  use Zing::Term;

  my $term = Zing::Term->new(Zing::KeyVal->new(name => 'nodes'));

  # $term->keyval;

=cut

=head1 DESCRIPTION

This package provides a mechanism for generating and validating (global and
local) resource identifiers.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 bucket

  bucket(Str)

This attribute is read-only, accepts C<(Str)> values, and is required.

=cut

=head2 facets

  facets(ArrayRef[Str])

This attribute is read-only, accepts C<(ArrayRef[Str])> values, and is optional.

=cut

=head2 handle

  handle(Str)

This attribute is read-only, accepts C<(Str)> values, and is required.

=cut

=head2 symbol

  symbol(Str)

This attribute is read-only, accepts C<(Str)> values, and is required.

=cut

=head2 system

  system(Str)

This attribute is read-only, accepts C<(Str)> values, and is required.

=cut

=head2 target

  target(Str)

This attribute is read-only, accepts C<(Str)> values, and is required.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 channel

  channel() : Str

The channel method validates and returns a "channel" resource identifier.

=over 4

=item channel example #1

  use Zing::Channel;

  Zing::Term->new(Zing::Channel->new(name => 'chat'));

  # $term->channel;

=back

=cut

=head2 data

  data() : Str

The data method validates and returns a "data" resource identifier.

=over 4

=item data example #1

  use Zing::Data;
  use Zing::Process;

  Zing::Term->new(Zing::Data->new(process => Zing::Process->new));

  # $term->data;

=back

=cut

=head2 domain

  domain() : Str

The domain method validates and returns a "domain" resource identifier.

=over 4

=item domain example #1

  use Zing::Domain;

  Zing::Term->new(Zing::Domain->new(name => 'transaction'));

  # $term->domain;

=back

=cut

=head2 kernel

  kernel() : Str

The kernel method validates and returns a "kernel" resource identifier.

=over 4

=item kernel example #1

  use Zing::Kernel;

  Zing::Term->new(Zing::Kernel->new(scheme => ['MyApp', [], 1]));

  # $term->kernel;

=back

=cut

=head2 keyval

  keyval() : Str

The keyval method validates and returns a "keyval" resource identifier.

=over 4

=item keyval example #1

  use Zing::KeyVal;

  Zing::Term->new(Zing::KeyVal->new(name => 'listeners'));

  # $term->keyval;

=back

=cut

=head2 mailbox

  mailbox() : Str

The mailbox method validates and returns a "mailbox" resource identifier.

=over 4

=item mailbox example #1

  use Zing::Mailbox;
  use Zing::Process;

  Zing::Term->new(Zing::Mailbox->new(process => Zing::Process->new));

  # $term->mailbox;

=back

=cut

=head2 process

  process() : Str

The process method validates and returns a "process" resource identifier.

=over 4

=item process example #1

  use Zing::Process;

  Zing::Term->new(Zing::Process->new);

  # $term->process;

=back

=cut

=head2 pubsub

  pubsub() : Str

The pubsub method validates and returns a "pubsub" resource identifier.

=over 4

=item pubsub example #1

  use Zing::PubSub;

  Zing::Term->new(Zing::PubSub->new(name => 'operations'));

  # $term->pubsub;

=back

=cut

=head2 queue

  queue() : Str

The queue method validates and returns a "queue" resource identifier.

=over 4

=item queue example #1

  use Zing::Queue;

  Zing::Term->new(Zing::Queue->new(name => 'workflows'));

  # $term->queue;

=back

=cut

=head2 registry

  registry() : Str

The registry method validates and returns a "registry" resource identifier.

=over 4

=item registry example #1

  use Zing::Registry;

  Zing::Term->new(Zing::Registry->new(name => 'campaigns'));

  # $term->registry;

=back

=cut

=head2 repo

  repo() : Str

The repo method validates and returns a "repo" resource identifier.

=over 4

=item repo example #1

  use Zing::Repo;

  Zing::Term->new(Zing::Repo->new(name => 'miscellaneous'));

  # $term->repo;

=back

=cut

=head2 string

  string() : Str

The string method returns a resource identifier. This method is called
automatically when the object is used as a string.

=over 4

=item string example #1

  # given: synopsis

  $term->string;

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
