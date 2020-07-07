package Zing::Types;

use 5.014;

use strict;
use warnings;

use Data::Object::Types::Keywords;

use base 'Data::Object::Types::Library';

extends 'Types::Standard';

our $VERSION = '0.12'; # VERSION

register {
  name => 'Channel',
  parent => 'Object',
  validation => is_instance_of('Zing::Channel'),
};

register {
  name => 'Data',
  parent => 'Object',
  validation => is_instance_of('Zing::Data'),
};

register {
  name => 'Domain',
  parent => 'Object',
  validation => is_instance_of('Zing::Domain'),
};

register {
  name => 'Error',
  parent => 'Object',
  validation => is_instance_of('Zing::Error'),
};

register {
  name => 'Flow',
  parent => 'Object',
  validation => is_instance_of('Zing::Flow'),
};

register {
  name => 'Fork',
  parent => 'Object',
  validation => is_instance_of('Zing::Fork'),
};

declare 'Interupt',
  as Enum([qw(CHLD HUP INT QUIT TERM USR1 USR2)]);

register {
  name => 'Kernel',
  parent => 'Object',
  validation => is_instance_of('Zing::Kernel'),
};

register {
  name => 'KeyVal',
  parent => 'Object',
  validation => is_instance_of('Zing::KeyVal'),
};

register {
  name => 'Logic',
  parent => 'Object',
  validation => is_instance_of('Zing::Logic'),
};

register {
  name => 'Loop',
  parent => 'Object',
  validation => is_instance_of('Zing::Loop'),
};

register {
  name => 'Logger',
  parent => 'Object',
  validation => is_instance_of('FlightRecorder'),
};

register {
  name => 'Mailbox',
  parent => 'Object',
  validation => is_instance_of('Zing::Mailbox'),
};

register {
  name => 'Node',
  parent => 'Object',
  validation => is_instance_of('Zing::Node'),
};

register {
  name => 'Poll',
  parent => 'Object',
  validation => is_instance_of('Zing::Poll'),
};

register {
  name => 'Process',
  parent => 'Object',
  validation => is_instance_of('Zing::Process'),
};

register {
  name => 'PubSub',
  parent => 'Object',
  validation => is_instance_of('Zing::PubSub'),
};

register {
  name => 'Queue',
  parent => 'Object',
  validation => is_instance_of('Zing::Queue'),
};

register {
  name => 'Registry',
  parent => 'Object',
  validation => is_instance_of('Zing::Registry'),
};

register {
  name => 'Redis',
  parent => 'Object',
  validation => is_instance_of('Redis'),
};

register {
  name => 'Repo',
  parent => 'Object',
  validation => is_instance_of('Zing::Repo'),
};

declare 'Schedule',
  as Tuple([Str(), ArrayRef([Str()]), HashRef()]);

declare 'Scheme',
  as Tuple([Str(), ArrayRef(), Int()]);

register {
  name => 'Server',
  parent => 'Object',
  validation => is_instance_of('Zing::Server'),
};

register {
  name => 'Space',
  parent => 'Object',
  validation => is_instance_of('Data::Object::Space'),
};

register {
  name => 'Store',
  parent => 'Object',
  validation => is_instance_of('Zing::Store'),
};

register {
  name => 'Task',
  parent => 'Object',
  validation => is_instance_of('Zing::Task'),
};

register {
  name => 'Watcher',
  parent => 'Object',
  validation => is_instance_of('Zing::Watcher'),
};

register {
  name => 'Worker',
  parent => 'Object',
  validation => is_instance_of('Zing::Worker'),
};

register {
  name => 'Zing',
  parent => 'Object',
  validation => is_instance_of('Zing'),
};

1;
=encoding utf8

=head1 NAME

Zing::Types - Type Library

=cut

=head1 ABSTRACT

Type Library

=cut

=head1 SYNOPSIS

  package main;

  use Zing::Types;

  1;

=cut

=head1 DESCRIPTION

This package provides type constraint for the L<Zing> process management
system.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 CONSTRAINTS

This package declares the following type constraints:

=cut

=head2 channel

  Channel

This type is defined in the L<Zing::Types> library.

=over 4

=item channel parent

  Object

=back

=over 4

=item channel composition

  InstanceOf["Zing::Channel"]

=back

=over 4

=item channel example #1

  # given: synopsis

  use Zing::Channel;

  my $chan = Zing::Channel->new(name => 'share');

=back

=cut

=head2 data

  Data

This type is defined in the L<Zing::Types> library.

=over 4

=item data parent

  Object

=back

=over 4

=item data composition

  InstanceOf["Zing::Data"]

=back

=over 4

=item data example #1

  # given: synopsis

  use Zing::Data;
  use Zing::Process;

  my $data = Zing::Data->new(process => Zing::Process->new);

=back

=cut

=head2 domain

  Domain

This type is defined in the L<Zing::Types> library.

=over 4

=item domain parent

  Object

=back

=over 4

=item domain composition

  InstanceOf["Zing::Domain"]

=back

=over 4

=item domain example #1

  # given: synopsis

  use Zing::Domain;

  my $domain = Zing::Domain->new(name => 'exchange');

=back

=cut

=head2 flow

  Flow

This type is defined in the L<Zing::Types> library.

=over 4

=item flow parent

  Object

=back

=over 4

=item flow composition

  InstanceOf["Zing::Flow"]

=back

=over 4

=item flow example #1

  # given: synopsis

  use Zing::Flow;

  my $flow = Zing::Flow->new(name => 'step_1', code => sub {1});

=back

=cut

=head2 fork

  Fork

This type is defined in the L<Zing::Types> library.

=over 4

=item fork parent

  Object

=back

=over 4

=item fork composition

  InstanceOf["Zing::Fork"]

=back

=over 4

=item fork example #1

  # given: synopsis

  use Zing::Fork;
  use Zing::Process;

  my $scheme = ['MyApp', [], 1];
  my $fork = Zing::Fork->new(scheme => $scheme, parent => Zing::Process->new);

=back

=cut

=head2 interupt

  Interupt

This type is defined in the L<Zing::Types> library.

=over 4

=item interupt composition

  Enum[qw(CHLD HUP INT QUIT TERM USR1 USR2)]

=back

=over 4

=item interupt example #1

  # given: synopsis

  'QUIT'

=back

=cut

=head2 kernel

  Kernel

This type is defined in the L<Zing::Types> library.

=over 4

=item kernel parent

  Object

=back

=over 4

=item kernel composition

  InstanceOf["Zing::Kernel"]

=back

=over 4

=item kernel example #1

  # given: synopsis

  use Zing::Kernel;

  my $kernel = Zing::Kernel->new(scheme => ['MyApp', [], 1]);

=back

=cut

=head2 keyval

  KeyVal

This type is defined in the L<Zing::Types> library.

=over 4

=item keyval parent

  Object

=back

=over 4

=item keyval composition

  InstanceOf["Zing::KeyVal"]

=back

=over 4

=item keyval example #1

  # given: synopsis

  use Zing::KeyVal;

  my $keyval = Zing::KeyVal->new(name => 'notes');

=back

=cut

=head2 logger

  Logger

This type is defined in the L<Zing::Types> library.

=over 4

=item logger parent

  Object

=back

=over 4

=item logger composition

  InstanceOf["Zing::Logger"]

=back

=over 4

=item logger example #1

  # given: synopsis

  use FlightRecorder;

  my $logger = FlightRecorder->new;

=back

=cut

=head2 logic

  Logic

This type is defined in the L<Zing::Types> library.

=over 4

=item logic parent

  Object

=back

=over 4

=item logic composition

  InstanceOf["Zing::Logic"]

=back

=over 4

=item logic example #1

  # given: synopsis

  use Zing::Logic;
  use Zing::Process;

  my $process = Zing::Process->new;
  my $logic = Zing::Logic->new(process => $process);

=back

=cut

=head2 loop

  Loop

This type is defined in the L<Zing::Types> library.

=over 4

=item loop parent

  Object

=back

=over 4

=item loop composition

  InstanceOf["Zing::Loop"]

=back

=over 4

=item loop example #1

  # given: synopsis

  use Zing::Flow;
  use Zing::Loop;

  my $loop = Zing::Loop->new(
    flow => Zing::Flow->new(name => 'init', code => sub {1})
  );

=back

=cut

=head2 mailbox

  Mailbox

This type is defined in the L<Zing::Types> library.

=over 4

=item mailbox parent

  Object

=back

=over 4

=item mailbox composition

  InstanceOf["Zing::Mailbox"]

=back

=over 4

=item mailbox example #1

  # given: synopsis

  use Zing::Mailbox;
  use Zing::Process;

  my $mailbox = Zing::Mailbox->new(process => Zing::Process->new);

=back

=cut

=head2 node

  Node

This type is defined in the L<Zing::Types> library.

=over 4

=item node parent

  Object

=back

=over 4

=item node composition

  InstanceOf["Zing::Node"]

=back

=over 4

=item node example #1

  # given: synopsis

  use Zing::Node;

  my $node = Zing::Node->new;

=back

=cut

=head2 poll

  Poll

This type is defined in the L<Zing::Types> library.

=over 4

=item poll parent

  Object

=back

=over 4

=item poll composition

  InstanceOf["Zing::Poll"]

=back

=over 4

=item poll example #1

  # given: synopsis

  use Zing::Poll;
  use Zing::KeyVal;

  my $keyval = Zing::KeyVal->new(name => 'notes');
  my $poll = Zing::Poll->new(name => 'last-week', repo => $keyval);

=back

=cut

=head2 process

  Process

This type is defined in the L<Zing::Types> library.

=over 4

=item process parent

  Object

=back

=over 4

=item process composition

  InstanceOf["Zing::Process"]

=back

=over 4

=item process example #1

  # given: synopsis

  use Zing::Process;

  my $process = Zing::Process->new;

=back

=cut

=head2 pubsub

  PubSub

This type is defined in the L<Zing::Types> library.

=over 4

=item pubsub parent

  Object

=back

=over 4

=item pubsub composition

  InstanceOf["Zing::PubSub"]

=back

=over 4

=item pubsub example #1

  # given: synopsis

  use Zing::PubSub;

  my $pubsub = Zing::PubSub->new(name => 'tasks');

=back

=cut

=head2 queue

  Queue

This type is defined in the L<Zing::Types> library.

=over 4

=item queue parent

  Object

=back

=over 4

=item queue composition

  InstanceOf["Zing::Queue"]

=back

=over 4

=item queue example #1

  # given: synopsis

  use Zing::Queue;

  my $queue = Zing::Queue->new(name => 'tasks');

=back

=cut

=head2 redis

  Redis

This type is defined in the L<Zing::Types> library.

=over 4

=item redis parent

  Object

=back

=over 4

=item redis composition

  InstanceOf["Zing::Redis"]

=back

=over 4

=item redis example #1

  # given: synopsis

  bless {}, 'Redis';

=back

=cut

=head2 registry

  Registry

This type is defined in the L<Zing::Types> library.

=over 4

=item registry parent

  Object

=back

=over 4

=item registry composition

  InstanceOf["Zing::Registry"]

=back

=over 4

=item registry example #1

  # given: synopsis

  use Zing::Process;
  use Zing::Registry;

  my $process = Zing::Process->new;
  my $registry = Zing::Registry->new(process => $process);

=back

=cut

=head2 repo

  Repo

This type is defined in the L<Zing::Types> library.

=over 4

=item repo parent

  Object

=back

=over 4

=item repo composition

  InstanceOf["Zing::Repo"]

=back

=over 4

=item repo example #1

  # given: synopsis

  use Zing::Repo;

  my $repo = Zing::Repo->new(name => 'repo');

=back

=cut

=head2 schedule

  Schedule

This type is defined in the L<Zing::Types> library.

=over 4

=item schedule composition

  Tuple[Str, ArrayRef[Str], HashRef]

=back

=over 4

=item schedule example #1

  # given: synopsis

  # at 00:00 on day-of-month 1 in january

  ['0 0 1 1 *', ['task_queue'], { task => 'execute' }];

=back

=over 4

=item schedule example #2

  # given: synopsis

  # at 00:00 on saturday

  ['0 0 * * SAT', ['task_queue'], { task => 'execute' }];

=back

=over 4

=item schedule example #3

  # given: synopsis

  # at minute 0 (hourly)

  ['0 * * * *', ['task_queue'], { task => 'execute' }];

=back

=cut

=head2 scheme

  Scheme

This type is defined in the L<Zing::Types> library.

=over 4

=item scheme composition

  Tuple[Str, ArrayRef, Int]

=back

=over 4

=item scheme example #1

  # given: synopsis

  ['MyApp', [], 1_000];

=back

=cut

=head2 server

  Server

This type is defined in the L<Zing::Types> library.

=over 4

=item server parent

  Object

=back

=over 4

=item server composition

  InstanceOf["Zing::Server"]

=back

=over 4

=item server example #1

  # given: synopsis

  use Zing::Server;

  my $server = Zing::Server->new;

=back

=cut

=head2 space

  Space

This type is defined in the L<Zing::Types> library.

=over 4

=item space parent

  Object

=back

=over 4

=item space composition

  InstanceOf["Zing::Space"]

=back

=over 4

=item space example #1

  # given: synopsis

  use Data::Object::Space;

  Data::Object::Space->new('MyApp');

=back

=cut

=head2 store

  Store

This type is defined in the L<Zing::Types> library.

=over 4

=item store parent

  Object

=back

=over 4

=item store composition

  InstanceOf["Zing::Store"]

=back

=over 4

=item store example #1

  # given: synopsis

  use Zing::Store;

  my $store = Zing::Store->new;

=back

=cut

=head2 watcher

  Watcher

This type is defined in the L<Zing::Types> library.

=over 4

=item watcher parent

  Object

=back

=over 4

=item watcher composition

  InstanceOf["Zing::Watcher"]

=back

=over 4

=item watcher example #1

  # given: synopsis

  bless {}, 'Zing::Watcher';

=back

=cut

=head2 worker

  Worker

This type is defined in the L<Zing::Types> library.

=over 4

=item worker parent

  Object

=back

=over 4

=item worker composition

  InstanceOf["Zing::Worker"]

=back

=over 4

=item worker example #1

  # given: synopsis

  bless {}, 'Zing::Worker';

=back

=cut

=head2 zing

  Zing

This type is defined in the L<Zing::Types> library.

=over 4

=item zing parent

  Object

=back

=over 4

=item zing composition

  InstanceOf["Zing::Zing"]

=back

=over 4

=item zing example #1

  # given: synopsis

  use Zing;

  my $zing = Zing->new(scheme => ['MyApp', [], 1]);

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
