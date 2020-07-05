use 5.014;

use strict;
use warnings;
use routines;

use lib 't/app';
use lib 't/lib';

use Test::Auto;
use Test::More;
use Test::Zing;

=name

Zing::Types

=cut

=tagline

Type Library

=cut

=abstract

Type Library

=cut

=synopsis

  package main;

  use Zing::Types;

  1;

=cut

=libraries

Types::Standard

=cut

=description

This package provides type constraint for the L<Zing> process management
system.

=cut

=type Channel

  Channel

=type-library Channel

Zing::Types

=type-composite Channel

  InstanceOf["Zing::Channel"]

=type-parent Channel

  Object

=type-example-1 Channel

  # given: synopsis

  use Zing::Channel;

  my $chan = Zing::Channel->new(name => 'share');

=cut

=type Data

  Data

=type-library Data

Zing::Types

=type-composite Data

  InstanceOf["Zing::Data"]

=type-parent Data

  Object

=type-example-1 Data

  # given: synopsis

  use Zing::Data;
  use Zing::Process;

  my $data = Zing::Data->new(process => Zing::Process->new);

=cut

=type Domain

  Domain

=type-library Domain

Zing::Types

=type-composite Domain

  InstanceOf["Zing::Domain"]

=type-parent Domain

  Object

=type-example-1 Domain

  # given: synopsis

  use Zing::Domain;

  my $domain = Zing::Domain->new(name => 'exchange');

=cut

=type Flow

  Flow

=type-library Flow

Zing::Types

=type-composite Flow

  InstanceOf["Zing::Flow"]

=type-parent Flow

  Object

=type-example-1 Flow

  # given: synopsis

  use Zing::Flow;

  my $flow = Zing::Flow->new(name => 'step_1', code => sub {1});

=cut

=type Fork

  Fork

=type-library Fork

Zing::Types

=type-composite Fork

  InstanceOf["Zing::Fork"]

=type-parent Fork

  Object

=type-example-1 Fork

  # given: synopsis

  use Zing::Fork;
  use Zing::Process;

  my $scheme = ['MyApp', [], 1];
  my $fork = Zing::Fork->new(scheme => $scheme, parent => Zing::Process->new);

=cut

=type Interupt

  Interupt

=type-library Interupt

Zing::Types

=type-composite Interupt

  Enum[qw(CHLD HUP INT QUIT TERM USR1 USR2)]

=type-example-1 Interupt

  # given: synopsis

  'QUIT'

=cut

=type Kernel

  Kernel

=type-library Kernel

Zing::Types

=type-composite Kernel

  InstanceOf["Zing::Kernel"]

=type-parent Kernel

  Object

=type-example-1 Kernel

  # given: synopsis

  use Zing::Kernel;

  my $kernel = Zing::Kernel->new(scheme => ['MyApp', [], 1]);

=cut

=type KeyVal

  KeyVal

=type-library KeyVal

Zing::Types

=type-composite KeyVal

  InstanceOf["Zing::KeyVal"]

=type-parent KeyVal

  Object

=type-example-1 KeyVal

  # given: synopsis

  use Zing::KeyVal;

  my $keyval = Zing::KeyVal->new(name => 'notes');

=cut

=type Logic

  Logic

=type-library Logic

Zing::Types

=type-composite Logic

  InstanceOf["Zing::Logic"]

=type-parent Logic

  Object

=type-example-1 Logic

  # given: synopsis

  use Zing::Logic;
  use Zing::Process;

  my $process = Zing::Process->new;
  my $logic = Zing::Logic->new(process => $process);

=cut

=type Loop

  Loop

=type-library Loop

Zing::Types

=type-composite Loop

  InstanceOf["Zing::Loop"]

=type-parent Loop

  Object

=type-example-1 Loop

  # given: synopsis

  use Zing::Flow;
  use Zing::Loop;

  my $loop = Zing::Loop->new(
    flow => Zing::Flow->new(name => 'init', code => sub {1})
  );

=cut

=type Logger

  Logger

=type-library Logger

Zing::Types

=type-composite Logger

  InstanceOf["Zing::Logger"]

=type-parent Logger

  Object

=type-example-1 Logger

  # given: synopsis

  use FlightRecorder;

  my $logger = FlightRecorder->new;

=cut

=type Mailbox

  Mailbox

=type-library Mailbox

Zing::Types

=type-composite Mailbox

  InstanceOf["Zing::Mailbox"]

=type-parent Mailbox

  Object

=type-example-1 Mailbox

  # given: synopsis

  use Zing::Mailbox;
  use Zing::Process;

  my $mailbox = Zing::Mailbox->new(process => Zing::Process->new);

=cut

=type Node

  Node

=type-library Node

Zing::Types

=type-composite Node

  InstanceOf["Zing::Node"]

=type-parent Node

  Object

=type-example-1 Node

  # given: synopsis

  use Zing::Node;

  my $node = Zing::Node->new;

=cut

=type Poll

  Poll

=type-library Poll

Zing::Types

=type-composite Poll

  InstanceOf["Zing::Poll"]

=type-parent Poll

  Object

=type-example-1 Poll

  # given: synopsis

  use Zing::Poll;
  use Zing::KeyVal;

  my $keyval = Zing::KeyVal->new(name => 'notes');
  my $poll = Zing::Poll->new(name => 'last-week', repo => $keyval);

=cut

=type Process

  Process

=type-library Process

Zing::Types

=type-composite Process

  InstanceOf["Zing::Process"]

=type-parent Process

  Object

=type-example-1 Process

  # given: synopsis

  use Zing::Process;

  my $process = Zing::Process->new;

=cut

=type PubSub

  PubSub

=type-library PubSub

Zing::Types

=type-composite PubSub

  InstanceOf["Zing::PubSub"]

=type-parent PubSub

  Object

=type-example-1 PubSub

  # given: synopsis

  use Zing::PubSub;

  my $pubsub = Zing::PubSub->new(name => 'tasks');

=cut

=type Queue

  Queue

=type-library Queue

Zing::Types

=type-composite Queue

  InstanceOf["Zing::Queue"]

=type-parent Queue

  Object

=type-example-1 Queue

  # given: synopsis

  use Zing::Queue;

  my $queue = Zing::Queue->new(name => 'tasks');

=cut

=type Registry

  Registry

=type-library Registry

Zing::Types

=type-composite Registry

  InstanceOf["Zing::Registry"]

=type-parent Registry

  Object

=type-example-1 Registry

  # given: synopsis

  use Zing::Process;
  use Zing::Registry;

  my $process = Zing::Process->new;
  my $registry = Zing::Registry->new(process => $process);

=cut

=type Redis

  Redis

=type-library Redis

Zing::Types

=type-composite Redis

  InstanceOf["Zing::Redis"]

=type-parent Redis

  Object

=type-example-1 Redis

  # given: synopsis

  bless {}, 'Redis';

=cut

=type Repo

  Repo

=type-library Repo

Zing::Types

=type-composite Repo

  InstanceOf["Zing::Repo"]

=type-parent Repo

  Object

=type-example-1 Repo

  # given: synopsis

  use Zing::Repo;

  my $repo = Zing::Repo->new(name => 'repo');

=cut

=type Schedule

  Schedule

=type-library Schedule

Zing::Types

=type-composite Schedule

  Tuple[Str, ArrayRef[Str], HashRef]

=type-example-1 Schedule

  # given: synopsis

  # at 00:00 on day-of-month 1 in january

  ['0 0 1 1 *', ['task_queue'], { task => 'execute' }];

=type-example-2 Schedule

  # given: synopsis

  # at 00:00 on saturday

  ['0 0 * * SAT', ['task_queue'], { task => 'execute' }];

=type-example-3 Schedule

  # given: synopsis

  # at minute 0 (hourly)

  ['0 * * * *', ['task_queue'], { task => 'execute' }];

=cut

=type Scheme

  Scheme

=type-library Scheme

Zing::Types

=type-composite Scheme

  Tuple[Str, ArrayRef, Int]

=type-example-1 Scheme

  # given: synopsis

  ['MyApp', [], 1_000];

=cut

=type Server

  Server

=type-library Server

Zing::Types

=type-composite Server

  InstanceOf["Zing::Server"]

=type-parent Server

  Object

=type-example-1 Server

  # given: synopsis

  use Zing::Server;

  my $server = Zing::Server->new;

=cut

=type Space

  Space

=type-library Space

Zing::Types

=type-composite Space

  InstanceOf["Zing::Space"]

=type-parent Space

  Object

=type-example-1 Space

  # given: synopsis

  use Data::Object::Space;

  Data::Object::Space->new('MyApp');

=cut

=type Store

  Store

=type-library Store

Zing::Types

=type-composite Store

  InstanceOf["Zing::Store"]

=type-parent Store

  Object

=type-example-1 Store

  # given: synopsis

  use Zing::Store;

  my $store = Zing::Store->new;

=cut

=type Watcher

  Watcher

=type-library Watcher

Zing::Types

=type-composite Watcher

  InstanceOf["Zing::Watcher"]

=type-parent Watcher

  Object

=type-example-1 Watcher

  # given: synopsis

  bless {}, 'Zing::Watcher';

=cut

=type Worker

  Worker

=type-library Worker

Zing::Types

=type-composite Worker

  InstanceOf["Zing::Worker"]

=type-parent Worker

  Object

=type-example-1 Worker

  # given: synopsis

  bless {}, 'Zing::Worker';

=cut

=type Zing

  Zing

=type-library Zing

Zing::Types

=type-composite Zing

  InstanceOf["Zing::Zing"]

=type-parent Zing

  Object

=type-example-1 Zing

  # given: synopsis

  use Zing;

  my $zing = Zing->new(scheme => ['MyApp', [], 1]);

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
