package Zing::Term;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;
use Data::Object::Space;

extends 'Zing::Class';

use Scalar::Util ();

use overload '""' => 'string';

our $VERSION = '0.21'; # VERSION

# ATTRIBUTES

has 'handle' => (
  is => 'ro',
  isa => 'Name',
  req => 1,
);

has 'symbol' => (
  is => 'ro',
  isa => 'Name',
  req => 1,
);

has 'bucket' => (
  is => 'ro',
  isa => 'Name',
  req => 1,
);

has 'system' => (
  is => 'ro',
  isa => 'Name',
  req => 1,
);

has 'target' => (
  is => 'ro',
  isa => 'Name',
  req => 1,
);

# BUILDERS

state $symbols = {
  'Zing::Channel'  => 'channel',
  'Zing::Data'     => 'data',
  'Zing::Domain'   => 'domain',
  'Zing::Kernel'   => 'kernel',
  'Zing::KeyVal'   => 'keyval',
  'Zing::Lookup'   => 'lookup',
  'Zing::Mailbox'  => 'mailbox',
  'Zing::Meta'     => 'meta',
  'Zing::Process'  => 'process',
  'Zing::PubSub'   => 'pubsub',
  'Zing::Queue'    => 'queue',
  'Zing::Repo'     => 'repo',
};

fun BUILDARGS($self, $item, @data) {
  my $args = {};

  if (Scalar::Util::blessed($item)) {
    if ($item->isa('Zing::Data')) {
      $args->{symbol} = $symbols->{'Zing::Data'};
      $args->{bucket} = $item->name;
    }
    elsif ($item->isa('Zing::Lookup')) {
      $args->{symbol} = $symbols->{'Zing::Lookup'};
      $args->{bucket} = $item->name;
    }
    elsif ($item->isa('Zing::Domain')) {
      $args->{symbol} = $symbols->{'Zing::Domain'};
      $args->{bucket} = $item->name;
    }
    elsif ($item->isa('Zing::Channel')) {
      $args->{symbol} = $symbols->{'Zing::Channel'};
      $args->{bucket} = $item->name;
    }
    elsif ($item->isa('Zing::Kernel')) {
      $args->{symbol} = $symbols->{'Zing::Kernel'};
      $args->{bucket} = $item->name;
    }
    elsif ($item->isa('Zing::Mailbox')) {
      $args->{symbol} = $symbols->{'Zing::Mailbox'};
      $args->{bucket} = $item->name;
    }
    elsif ($item->isa('Zing::Process')) {
      $args->{symbol} = $symbols->{'Zing::Process'};
      $args->{bucket} = $item->name;
    }
    elsif ($item->isa('Zing::Queue')) {
      $args->{symbol} = $symbols->{'Zing::Queue'};
      $args->{bucket} = $item->name;
    }
    elsif ($item->isa('Zing::Meta')) {
      $args->{symbol} = $symbols->{'Zing::Meta'};
      $args->{bucket} = $item->name;
    }
    elsif ($item->isa('Zing::KeyVal')) {
      $args->{symbol} = $symbols->{'Zing::KeyVal'};
      $args->{bucket} = $item->name;
    }
    elsif ($item->isa('Zing::PubSub')) {
      $args->{symbol} = $symbols->{'Zing::PubSub'};
      $args->{bucket} = $item->name;
    }
    elsif ($item->isa('Zing::Repo')) {
      $args->{symbol} = $symbols->{'Zing::Repo'};
      $args->{bucket} = $item->name;
    }
    else {
      $self->throw(error_term_unknow_object($item));
    }
    $args->{target} = ($item->env->target || 'global');
    $args->{handle} = ($item->env->handle || 'main');
    $args->{system} = 'zing';
  }
  elsif(defined $item && !ref $item) {
    my $schema = [split /:/, "$item", 5];

    my $system = $schema->[0];
    my $handle = $schema->[1];
    my $target = $schema->[2];
    my $symbol = $schema->[3];
    my $bucket = $schema->[4];

    unless ($system eq 'zing') {
      $self->throw(error_term_unknow_system("$item"));
    }
    unless (grep {$_ eq $symbol} values %$symbols) {
      $self->throw(error_term_unknow_symbol("$item"));
    }

    $args->{system} = $system;
    $args->{handle} = $handle;
    $args->{target} = $target;
    $args->{symbol} = $symbol;
    $args->{bucket} = $bucket;
  }
  else {
    $self->throw(error_term_unknown());
  }

  return $args;
}

# METHODS

method channel() {
  unless ($self->symbol eq 'channel') {
    $self->throw(error_term_invalid("channel"));
  }

  return $self->string;
}

method data() {
  unless ($self->symbol eq 'data') {
    $self->throw(error_term_invalid("data"));
  }

  return $self->string;
}

method domain() {
  unless ($self->symbol eq 'domain') {
    $self->throw(error_term_invalid("domain"));
  }

  return $self->string;
}

method kernel() {
  unless ($self->symbol eq 'kernel') {
    $self->throw(error_term_invalid("kernel"));
  }

  return $self->string;
}

method keyval() {
  unless ($self->symbol eq 'keyval') {
    $self->throw(error_term_invalid("keyval"));
  }

  return $self->string;
}

method lookup() {
  unless ($self->symbol eq 'lookup') {
    $self->throw(error_term_invalid("lookup"));
  }

  return $self->string;
}

method mailbox() {
  unless ($self->symbol eq 'mailbox') {
    $self->throw(error_term_invalid("mailbox"));
  }

  return $self->string;
}

method meta() {
  unless ($self->symbol eq 'meta') {
    $self->throw(error_term_invalid("meta"));
  }

  return $self->string;
}

method object() {
  require Zing::Env;

  my $env = Zing::Env->new(
    handle => $self->handle,
    target => $self->target,
  );

  my $space = Data::Object::Space->new(
    ({reverse %$symbols})->{$self->symbol}
  );

  return $space->build(env => $env, name => $self->bucket);
}

method process() {
  unless ($self->symbol eq 'process') {
    $self->throw(error_term_invalid("process"));
  }

  return $self->string;
}

method pubsub() {
  unless ($self->symbol eq 'pubsub') {
    $self->throw(error_term_invalid("pubsub"));
  }

  return $self->string;
}

method queue() {
  unless ($self->symbol eq 'queue') {
    $self->throw(error_term_invalid("queue"));
  }

  return $self->string;
}

method repo() {
  unless ($self->symbol eq 'repo') {
    $self->throw(error_term_invalid('repo'));
  }

  return $self->string;
}

method string() {
  my $system = $self->system;
  my $handle = $self->handle;
  my $target = $self->target;
  my $symbol = $self->symbol;
  my $bucket = $self->bucket;

  return lc join ':', $system, $handle, $target, $symbol, $bucket;
}

# ERRORS

fun error_term_invalid(Str $name) {
  code => 'error_term_invalid',
  message => qq(Error in term: not a "$name" term),
}

fun error_term_unknown() {
  code => 'error_term_unknown',
  message => qq(Unrecognizable term (or object) provided),
}

fun error_term_unknow_object(Object $item) {
  code => 'error_term_unknow_object',
  message => qq(Error in term: Unrecognizable "object": $item),
}

fun error_term_unknow_symbol(Str $term) {
  code => 'error_term_unknow_symbol',
  message => qq(Error in term: Unrecognizable "symbol" in: $term),
}

fun error_term_unknow_system(Str $term) {
  code => 'error_term_unknow_system',
  message => qq(Error in term: Unrecognizable "system" in: $term),
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

  Zing::Term->new(Zing::Data->new(name => '0.0.0.0'));

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

=head2 lookup

  lookup() : Str

The lookup method validates and returns a "lookup" resource identifier.

=over 4

=item lookup example #1

  use Zing::Lookup;

  Zing::Term->new(Zing::Lookup->new(name => 'employees'));

  # $term->lookup;

=back

=cut

=head2 mailbox

  mailbox() : Str

The mailbox method validates and returns a "mailbox" resource identifier.

=over 4

=item mailbox example #1

  use Zing::Mailbox;
  use Zing::Process;

  Zing::Term->new(Zing::Mailbox->new(name => '0.0.0.0'));

  # $term->mailbox;

=back

=cut

=head2 meta

  meta() : Str

The meta method validates and returns a "meta" resource identifier.

=over 4

=item meta example #1

  use Zing::Meta;

  Zing::Term->new(Zing::Meta->new(name => 'random'));

  # $term->meta;

=back

=cut

=head2 object

  object() : Object

The object method reifies an object from its resource identifier.

=over 4

=item object example #1

  use Zing::Process;

  my $term = Zing::Term->new(Zing::Process->new);

  $term->object;

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
