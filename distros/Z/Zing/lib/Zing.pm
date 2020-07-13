package Zing;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::Kernel';

our $VERSION = '0.13'; # VERSION

# ATTRIBUTES

has 'scheme' => (
  is => 'ro',
  isa => 'Scheme',
  req => 1,
);

# METHODS

method start() {
  return $self->execute;
}

1;

=encoding utf8

=head1 NAME

Zing - Multi-Process Management System

=cut

=head1 ABSTRACT

Actor Toolkit and Multi-Process Management System

=cut

=head1 SYNOPSIS

  use Zing;

  my $zing = Zing->new(scheme => ['MyApp', [], 1]);

  # $zing->execute;

=cut

=head1 DESCRIPTION

This distribution includes an actor-model architecture toolkit and
multi-process management system which provides primatives for building
resilient, reactive, concurrent, distributed message-driven applications in
Perl 5. If you're unfamiliar with this architectural pattern, learn more about
L<"the actor model"|https://en.wikipedia.org/wiki/Actor_model>.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::Kernel>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 scheme

  scheme(Scheme)

This attribute is read-only, accepts C<(Scheme)> values, and is required.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 start

  start() : Kernel

The start method prepares the L<Zing::Kernel> and executes its event-loop.

=over 4

=item start example #1

  # given: synopsis

  $zing->start;

=back

=cut

=head1 PRIMATIVES

This distribution provides a collection of actor-model primitives which can be
used to create sophisticated and powerful distributed systems, organized within
intricate process topologies. The following is a directory of those primitives
listed by classification:

=head2 messaging

These classes facilitate message-passing and communications:

=over 4

=item *

L<Zing::Channel>: Shared Communication

=item *

L<Zing::Data>: Process Data

=item *

L<Zing::Domain>: Shared State Management

=item *

L<Zing::KeyVal>: Key/Value Store

=item *

L<Zing::Mailbox>: Process Mailbox

=item *

L<Zing::PubSub>: Pub/Sub Store

=item *

L<Zing::Queue>: Message Queue

=item *

L<Zing::Registry>: Process Registry

=item *

L<Zing::Repo>: Generic Store

=item *

L<Zing::Store>: Storage Abstraction

=back

=head2 processes

These base classes implement the underlying process (actor) logic:

=over 4

=item *

L<Zing>: Process Wrapper

=item *

L<Zing::Kernel>: Kernel Process

=item *

L<Zing::Launcher>: Scheme Launcher

=item *

L<Zing::Process>: Processing Unit

=item *

L<Zing::Ring>: Process Ring

=item *

L<Zing::Scheduler>: Scheme Launcher

=item *

L<Zing::Simple>: Simple Process

=item *

L<Zing::Single>: Single Process

=item *

L<Zing::Spawner>: Scheme Spawner

=item *

L<Zing::Timer>: Timer Process

=item *

L<Zing::Watcher>: Watcher Process

=item *

L<Zing::Worker>: Worker Process

=back

=head2 ready-made

These classes are ready-made process implementations using callbacks:

=over 4

=item *

L<Zing::Zang>: Process Implementation

=item *

L<Zing::Zang::Launcher>: Process Launcher

=item *

L<Zing::Zang::Simple>: Process Performer

=item *

L<Zing::Zang::Single>: Single-Task Process

=item *

L<Zing::Zang::Spawner>: Process Spawner

=item *

L<Zing::Zang::Timer>: Timer Process

=item *

L<Zing::Zang::Watcher>: Process Watcher

=item *

L<Zing::Zang::Worker>: Worker Process

=back

=cut

=head1 FEATURES

All features are implemented using classes and objects. The following is a list
of features currently enabled by this toolkit:

=cut

=head2 actor-model

  use Zing::Process;

  my $p1 = Zing::Process->new;
  my $p2 = Zing::Process->new;

  $p1->send($p2, { action => 'greetings' });

  say $p2->recv->{action}; # got it?

This distribution provides a toolkit for creating processes (actors) which can
be run in isolation and which communicate with other processes through
message-passing.

=cut

=head2 asynchronous

  # in process (1)
  use Zing::Domain;
  use Zing::Process;

  my $d1 = Zing::Domain->new(name => 'peers');
  my $p1 = Zing::Process->new(name => 'p1');

  $d1->push('mailboxes', $p1->mailbox->term);
  $p1->execute;

  # in process (2)
  use Zing::Domain;
  use Zing::Process;

  my $d2 = Zing::Domain->new(name => 'peers');
  my $p2 = Zing::Process->new(name => 'p2');

  my $mailboxes = $d2->get('mailboxes');

  for my $address (@$mailboxes) {
    # send each registered process a message
    $p2->send($address, { discovery => $p2->mailbox->term });
  }

  $p2->execute;

This distribution provides a multi-process management system which allows
processes to be deployed and managed separately having the ability to
communicate across threads of execution.

=cut

=head2 atomicity

  # in process (1)
  use Zing::KeyVal;

  my $i = 0;
  my $kv = Zing::KeyVal->new(name => 'stash');

  while ($i < 1_000) {
    $kv->send('random', { value => 1 });

    # my $data = $kv->recv('random');
  }

  # in process (2)
  use Zing::KeyVal;

  my $i = 0;
  my $kv = Zing::KeyVal->new(name => 'stash');

  while ($i < 1_000) {
    $kv->send('random', { value => 2 });

    # my $data = $kv->recv('random');
  }

This distribution provides data storage abstractions which perform atomic reads
and write by leveraging L<Redis|https://redis.io> as the default data storage
backend.

=cut

=head2 chainable

  use Zing::Process;
  use Zing::Ring;

  my $p1 = Zing::Process->new(name => 'p1');
  my $p2 = Zing::Process->new(name => 'p2');

  my $ring = Zing::Ring->new(processes => [$p1, $p2]);

  $ring->execute;

This distribution provides a mechanism for chaining (i.e. joining) two or more
processes together and executing them in a turn-based manner. This ability
allows you to design complex hierarchical process topologies.

=cut

=head2 channels

  # in process (1)
  use Zing::Channel;

  my $chan = Zing::Channel->new(name => 'chat');

  while (1) {
    if (my $data = $chan->recv) {
      # broadcast received
      warn $data->{text};
    }
  }

  # in process (2)
  use Zing::Channel;

  my $chan = Zing::Channel->new(name => 'chat');

  while (1) {
    if (my $data = $chan->recv) {
      # broadcast received
      warn $data->{text};
    }
  }

This distribution provides the means for braodcasting and communicating to
multiple processes simulaneously through channels which are similar to FIFO
queues.

=cut

=head2 clusterable

  # in process (1) on cluster (1)
  use Zing::Queue;

  my $queue = Zing::Queue->new(name => 'tasks', target => 'global');

  # pull from global queue
  $queue->recv;

  # in process (1) on cluster (2)
  use Zing::Queue;

  my $queue = Zing::Queue->new(name => 'tasks', target => 'global');

  # pull from global queue
  $queue->recv;

This distribution provides support cross-cluster communication and thus
operations. Using federated Redis as the data storage backend means you can
scale your deployments without changing your implementations.

=cut

=head2 configuration

  # configure the namespace
  ZING_NS=app

  # enable process debugging tracing
  ZING_DEBUG=1

  # configure the namespace, same as ZING_NS (defaults to "main")
  ZING_HANDLE=app

  # configure where the command-line tool finds catridges
  ZING_HOME=/tmp

  # configure the hostname used in process registration
  ZING_HOST=0.0.0.0
  ZING_HOST=68.80.90.100

  # configure the resource target (e.g. when distributing across multiple hosts)
  ZING_TARGET='global' # or 'local'

  # configure the system datastore (defaults to 'Zing::Redis')
  ZING_STORE='Zing::Redis'

  # configure Redis driver without touching your source code
  ZING_REDIS='server=127.0.0.1:6379'
  ZING_REDIS='every=1_000_000,reconnect=60'
  ZING_REDIS='sentinels=127.0.0.1:12345|127.0.0.1:23456,sentinels_cnx_timeout=0.1'
  ZING_REDIS='server=192.168.0.1:6379,debug=0'

  # configure where the command-line tool finds catridges and PID files
  ZING_APPDIR=./
  ZING_PIDDIR=/tmp

This distribution provides environment variables that let you customize how
Zing operates and behaves without the need to modify source code. These
attributes are not required and fallback to sane defaults.

=cut

=head2 distributed

  # in process (1..n) on cluster (1)
  use Zing;

  my $zing = Zing->new(scheme => ['MyApp', [], 16]);

  $zing->execute;

  # in process (1..n) on cluster (2)
  use Zing;

  my $zing = Zing->new(scheme => ['MyApp', [], 16]);

  $zing->execute;

  # in process (1..n) on cluster (3)
  use Zing;

  my $zing = Zing->new(scheme => ['MyApp', [], 16]);

  $zing->execute;

This distribution provides a collection of actor-model primitives which can be
used to create sophisticated and powerful distributed systems, organized within
intricate process topologies.

=cut

=head2 event-driven

  # in process (1)
  package MyApp::FileUpoad;

  use parent 'Zing::Process';

  sub receive {
    my ($self, $from, $data) = @_;

    # react to file-upload events

    return;
  }

  my $p1 = MyApp::FileUpoad->new;

  $p1->execute;

  # in process (2)
  package MyApp::TextTranslate;

  use parent 'Zing::Process';

  sub receive {
    my ($self, $from, $data) = @_;

    # react to text-translate events

    return;
  }

  my $p2 = MyApp::TextTranslate->new;

  $p2->execute;

This distribution provides all the prerequisites needed to develop scalable
reactive event-driven applications distributed across one or several servers.

=cut

=head2 fifo-queues

  # in process (1)
  use Zing::Queue;

  my $queue = Zing::Queue->new(name => 'tasks');

  # pull from queue
  $queue->send({ command => { ... } });
  $queue->send({ command => { ... } });
  $queue->send({ command => { ... } });
  $queue->send({ command => { ... } });

  # in process (2)
  use Zing::Queue;

  my $queue = Zing::Queue->new(name => 'tasks');

  # pull from FIFO queue
  $queue->recv;

This distribution provides high-performance FIFO message queues which enhance
messaging across processes when the order of operations and events is critical
and where duplicates can't be tolerated.

=cut

=head2 hot-reloadable

  use Zing;
  use Zing::Daemon;

  my $daemon = Zing::Daemon->new(
    name => 'myapp-sleep',
    app => Zing->new(scheme => ['MyApp::Sleep', [], 4])
  );

  $daemon->execute; # pid 12345

  # $ kill -USR2 12345

This distribution provides zero-downtime through hot-reloading which is where
the process watchers (supervisors) keep the app running and gracefully reload
child processes at runtime.

=cut

=head2 log-shipping

  use Zing::Zang;

  my $zang = Zing::Zang->new(on_perform => sub {
    my ($self) = @_;

    $self->log->fatal('something went wrong');

    return;
  });

  $zang->execute;

  # tap the logs using the command-line tool

  # $ zing logs

This distribution provides the ability to ship the logs of individual processes
to a specific centralized channel which can be tapped asynchronously,
especially by the command-line tool.

=cut

=head2 mailboxes

  use Zing::Process;

  my $p1 = Zing::Process->new(name => 'p1');
  my $p2 = Zing::Process->new(name => 'p2');

  $p1->mailbox->send($p2->mailbox->term, { say => 'ehlo' });

  my $message = $p2->mailbox->recv;

  $p2->mailbox->reply($message, { say => 'helo' });

This distribution provides every process with its own unique mailbox which can
receive messages from other processes as a means of cooperating through message
passing.

=cut

=head2 management

  use Zing::Kernel;

  my $kernel = Zing::Kernel->new(scheme => ['MyApp::Logger', [], 2]);

  $kernel->execute;

This distribution provides a kernel process that can be used to manage the
deployment of child processes and is used to wrap cartridges by the
command-line tool when daemonizing process.

=cut

=head2 multitasking

  use Zing::Zang;

  my $zang = Zing::Zang->new(
    on_perform => sub {
      # do something
    },
    on_receive => sub {
      # handle something
    },
  );

  $zang->execute;

This distribution provides all processes with an event-loop that allows them to
perform multiple operations in sequence and supports operating in a
non-blocking manner.

=cut

=head2 non-blocking

  use Zing::Zang;

  my $zang = Zing::Zang->new(
    on_perform => sub {
      my ($self) = @_;

      $self->defer({ command => {...} }) and return;

      return;
    },
    on_receive => sub {
      my ($self, $from, $data) = @_;

      return unless $self->term eq $from; # from myself

      # do something

      return;
    }
  );

  $zang->exercise;

This distribution provides features that allow processes to operate in a
non-blocking manner, yielding and deferring operations, and chunking workloads.

=cut

=head2 parallelism

  use Zing::Process;

  my $p1 = Zing::Process->new;

  my $f1 = $p1->spawn(['MyApp', [id => 12345] 1]);
  my $f2 = $p1->spawn(['MyApp', [id => 12346] 1]);

This distribution provides multiple ways of executing operations in parallel,
including spawning processes via forking with the guarantee of not creating
zombie processes.

=cut

=head2 supervisors

  use Zing::Zang::Watcher;

  my $zang = Zing::Zang::Watcher->new(
    scheme => ['MyApp', [] 8]
  );

  $zang->exercise;

This distribution provides watcher processes which to supervise child processes
but also are capable of multitasking and performing other operations while
monitoring supervised processes.

=head2 virtual-actors

  use Zing::Zang::Spawner;

  my $zang = Zing::Zang::Spawner->new(
    queues => ['schemes']
  );

  $zang->exercise;

This distribution provides the ability to use virtual actors, which are
processes (actors) created on-demand as a result of some system event. This
feature is enabled by the L<Zing::Launcher> and L<Zing::Spawner> superclasses.

=cut

=head1 COMMANDS

Given the following process (actor):

  # in lib/MyApp.pm

  package MyApp;

  use parent 'Zing::Single';

  sub perform {
    # do something (once)
  }

  1;

With an application cartridge specifying 4 forks:

  # in app/myapp

  ['MyApp', [], 4]

The L<zing> command-line application lets you manage Zing applications from the
command-line using these commands:

=cut

=head2 start

  $ zing start app/myapp

The C<start> command loads an application I<cartridge> which returns a
L<"scheme"|Zing::Types/scheme> and runs it as a daemon.

=cut

=head2 stop

  $ zing stop app/myapp

The C<stop> command finds a running application by its PID (process ID) and
terminates the process.

=cut

=head2 logs

  $ zing logs --level fatal

The C<logs> command taps the centralized log source and outputs new events to
STDOUT (standard output).

=cut

=head1 SEE ALSO

L<The Actor Model|https://en.wikipedia.org/wiki/Actor_model>

L<Concurrent Computation|https://www.amazon.com/Actors-Concurrent-Computation-Distributed-Systems/dp/026251141X>

L<Concurrency in Go/Erlang|https://www.youtube.com/watch?v=2yiKUIDFc2I>

L<The Akka Project|https://github.com/akka/akka>

L<The Actorkit Project|https://github.com/influx6/actorkit>

L<The Orleans Project|http://dotnet.github.io/orleans>

L<The Pyakka Project|https://github.com/jodal/pykka>

L<The Reactive Manifesto|http://www.reactivemanifesto.org>

=head1 DISCLOSURES

The following is a list of all the known ways Zing is not like a traditional
actor-model system:

=over 4

=item *

In Zing, actors act independently and aren't beholden to a system manager.

=item *

In Zing, actors are always active (each runs its own infinite event-loop).

=item *

In Zing, actors can communicate unrestricted (no approved communicators).

=item *

In Zing, actors can block using C<poll> but do not block by default.

=item *

In Zing, the default datastore/backend is L<Redis|https://redis.io> which means
the system is (by default) subject to the guarantees and limitations of that
system. Data is serialized as L<JSON|https://json.org> and stored in
plain-text.

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
