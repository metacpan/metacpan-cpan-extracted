use 5.014;

use strict;
use warnings;
use routines;

use lib 't/lib';

use Test::Auto;
use Test::More;
use Test::Zing;

=name

Zing::App

=cut

=tagline

Object Reifier

=cut

=abstract

Object Reifier with Dependency Injection

=cut

=includes

method: for
method: cartridge
method: cartridge_namespace
method: cartridge_specification
method: channel
method: channel_namespace
method: channel_specification
method: cursor
method: cursor_namespace
method: cursor_specification
method: daemon
method: daemon_namespace
method: daemon_specification
method: data
method: data_namespace
method: data_specification
method: domain
method: domain_namespace
method: domain_specification
method: encoder
method: encoder_namespace
method: encoder_specification
method: fork
method: fork_namespace
method: fork_specification
method: id
method: id_namespace
method: id_specification
method: journal
method: journal_namespace
method: journal_specification
method: kernel
method: kernel_namespace
method: kernel_specification
method: keyval
method: keyval_namespace
method: keyval_specification
method: launcher
method: launcher_namespace
method: launcher_specification
method: logger
method: lookup
method: lookup_namespace
method: lookup_specification
method: mailbox
method: mailbox_namespace
method: mailbox_specification
method: meta
method: meta_namespace
method: meta_specification
method: process
method: process_namespace
method: process_specification
method: pubsub
method: pubsub_namespace
method: pubsub_specification
method: queue
method: queue_namespace
method: queue_specification
method: reify
method: repo
method: repo_namespace
method: repo_specification
method: ring
method: ring_namespace
method: ring_specification
method: ringer
method: ringer_namespace
method: ringer_specification
method: savepoint
method: savepoint_namespace
method: savepoint_specification
method: scheduler
method: scheduler_namespace
method: scheduler_specification
method: search
method: search_namespace
method: search_specification
method: simple
method: simple_namespace
method: simple_specification
method: single
method: single_namespace
method: single_specification
method: space
method: spawner
method: spawner_namespace
method: spawner_specification
method: store
method: store_namespace
method: store_specification
method: term
method: timer
method: timer_namespace
method: timer_specification
method: watcher
method: watcher_namespace
method: watcher_specification
method: worker
method: worker_namespace
method: worker_specification
method: zang
method: zing

=cut

=synopsis

  use Zing::App;

  my $app = Zing::App->new;

  # $app->queue(name => 'tasks')->send({
  #   job => time,
  #   ...
  # });

=cut

=libraries

Zing::Types

=cut

=attributes

env: ro, opt, Env
host: ro, opt, Str
name: ro, opt, Str
pid: ro, opt, Int

=cut

=description

This package provides an object which can dynamically load (reify) other
L<Zing> objects with dependencies.

=cut

=method for

The for method changes the C<env> and returns a new C<app> object.

=signature for

for(Any %args) : App

=example-1 for

  # given: synopsis

  $app = $app->for(
    handle => 'myapp',
    target => 'us-east'
  );

=cut

=method cartridge

The cartridge method returns a new L<Zing::Cartridge> object based on the current C<env>.

=signature cartridge

cartridge(Any @args) : Cartridge

=example-1 cartridge

  # given: synopsis

  my $cartridge = $app->cartridge(
    name => 'myapp',
  );

  # Zing::Cartridge->new(...)

=cut

=method cartridge_namespace

The cartridge_namespace method returns a wordlist that represents a
I<cartridge> class name.

=signature cartridge_namespace

cartridge_namespace() : ArrayRef[Str]

=example-1 cartridge_namespace

  # given: synopsis

  $app->cartridge_namespace;

  # ['zing', 'cartridge']

=cut

=method cartridge_specification

The cartridge_specification method returns a I<cartridge> specification, class
name and args, for the reifier.

=signature cartridge_specification

cartridge_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 cartridge_specification

  # given: synopsis

  $app->cartridge_specification;

  # [['zing', 'cartridge'], [@args]]

=cut

=method channel

The channel method returns a new L<Zing::Channel> object based on the currenrt C<env>.

=signature channel

channel(Any @args) : Channel

=example-1 channel

  # given: synopsis

  my $channel = $app->channel(
    name => 'messages',
  );

  # Zing::Channel->new(...)

=cut

=method channel_namespace

The channel_namespace method returns a wordlist that represents a I<channel>
class name.

=signature channel_namespace

channel_namespace() : ArrayRef[Str]

=example-1 channel_namespace

  # given: synopsis

  $app->channel_namespace;

  # ['zing', 'channel']

=cut

=method channel_specification

The channel_specification method returns a I<channel> specification, class name
and args, for the reifier.

=signature channel_specification

channel_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 channel_specification

  # given: synopsis

  $app->channel_specification;

  # [['zing', 'channel'], [@args]]

=cut

=method cursor

The cursor method returns a new L<Zing::Cursor> object based on the current C<env>.

=signature cursor

cursor(Any @args) : Cursor

=example-1 cursor

  # given: synopsis

  my $cursor = $app->cursor(
    lookup => $app->lookup(
      name => 'people',
    )
  );

  # Zing::Cursor->new(...)

=cut

=method cursor_namespace

The cursor_namespace method returns a wordlist that represents a I<cursor>
class name.

=signature cursor_namespace

cursor_namespace() : ArrayRef[Str]

=example-1 cursor_namespace

  # given: synopsis

  $app->cursor_namespace;

  # ['zing', 'cursor']

=cut

=method cursor_specification

The cursor_specification method returns a I<cursor> specification, class name
and args, for the reifier.

=signature cursor_specification

cursor_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 cursor_specification

  # given: synopsis

  $app->cursor_specification;

  # [['zing', 'cursor'], [@args]]

=cut

=method daemon

The daemon method returns a new L<Zing::Daemon> object based on the currenrt C<env>.

=signature daemon

daemon(Any @args) : Daemon

=example-1 daemon

  # given: synopsis

  my $daemon = $app->daemon(
    cartridge => $app->cartridge(
      name => 'myapp',
    )
  );

  # Zing::Daemon->new(...)

=cut

=method daemon_namespace

The daemon_namespace method returns a wordlist that represents a I<daemon>
class name.

=signature daemon_namespace

daemon_namespace() : ArrayRef[Str]

=example-1 daemon_namespace

  # given: synopsis

  $app->daemon_namespace;

  # ['zing', 'daemon']

=cut

=method daemon_specification

The daemon_specification method returns a I<daemon> specification, class name
and args, for the reifier.

=signature daemon_specification

daemon_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 daemon_specification

  # given: synopsis

  $app->daemon_specification;

  # [['zing', 'daemon'], [@args]]

=cut

=method data

The data method returns a new L<Zing::Data> object based on the current C<env>.

=signature data

data(Any @args) : Data

=example-1 data

  # given: synopsis

  my $data = $app->data(
    name => 'random',
  );

  # Zing::Data->new(...)

=cut

=method data_namespace

The data_namespace method returns a wordlist that represents a I<data> class
name.

=signature data_namespace

data_namespace() : ArrayRef[Str]

=example-1 data_namespace

  # given: synopsis

  $app->data_namespace;

  # ['zing', 'data']

=cut

=method data_specification

The data_specification method returns a I<data> specification, class name and
args, for the reifier.

=signature data_specification

data_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 data_specification

  # given: synopsis

  $app->data_specification;

  # [['zing', 'data'], [@args]]

=cut

=method domain

The domain method returns a new L<Zing::Domain> object based on the currenrt C<env>.

=signature domain

domain(Any @args) : Domain

=example-1 domain

  # given: synopsis

  my $domain = $app->domain(
    name => 'person',
  );

  # Zing::Domain->new(...)

=cut

=method domain_namespace

The domain_namespace method returns a wordlist that represents a I<domain>
class name.

=signature domain_namespace

domain_namespace() : ArrayRef[Str]

=example-1 domain_namespace

  # given: synopsis

  $app->domain_namespace;

  # ['zing', 'domain']

=cut

=method domain_specification

The domain_specification method returns a I<domain> specification, class name
and args, for the reifier.

=signature domain_specification

domain_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 domain_specification

  # given: synopsis

  $app->domain_specification;

  # [['zing', 'domain'], [@args]]

=cut

=method encoder

The encoder method returns a new L<Zing::Encoder> object based on the current C<env>.

=signature encoder

encoder(Any @args) : Encoder

=example-1 encoder

  # given: synopsis

  my $encoder = $app->encoder;

  # Zing::Encoder->new

=cut

=method encoder_namespace

The encoder_namespace method returns a wordlist that represents a I<encoder>
class name.

=signature encoder_namespace

encoder_namespace() : ArrayRef[Str]

=example-1 encoder_namespace

  # given: synopsis

  $app->encoder_namespace;

  # ['zing', 'encoder']

=cut

=method encoder_specification

The encoder_specification method returns a I<encoder> specification, class name
and args, for the reifier.

=signature encoder_specification

encoder_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 encoder_specification

  # given: synopsis

  $app->encoder_specification;

  # [['zing', 'encoder'], [@args]]

=cut

=method fork

The fork method returns a new L<Zing::Fork> object based on the currenrt C<env>.

=signature fork

fork(Any @args) : Fork

=example-1 fork

  # given: synopsis

  my $fork = $app->fork(
    parent => $app->process,
    scheme => ['MyApp', [], 1],
  );

  # Zing::Fork->new(...)

=cut

=method fork_namespace

The fork_namespace method returns a wordlist that represents a I<fork> class
name.

=signature fork_namespace

fork_namespace() : ArrayRef[Str]

=example-1 fork_namespace

  # given: synopsis

  $app->fork_namespace;

  # ['zing', 'fork']

=cut

=method fork_specification

The fork_specification method returns a I<fork> specification, class name and
args, for the reifier.

=signature fork_specification

fork_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 fork_specification

  # given: synopsis

  $app->fork_specification;

  # [['zing', 'fork'], [@args]]

=cut

=method id

The id method returns a new L<Zing::ID> object based on the current C<env>.

=signature id

id(Any @args) : ID

=example-1 id

  # given: synopsis

  my $id = $app->id;

  # Zing::ID->new(...)

=cut

=method id_namespace

The id_namespace method returns a wordlist that represents a I<id> class name.

=signature id_namespace

id_namespace() : ArrayRef[Str]

=example-1 id_namespace

  # given: synopsis

  $app->id_namespace;

  # ['zing', 'i-d']

=cut

=method id_specification

The id_specification method returns a I<id> specification, class name and args,
for the reifier.

=signature id_specification

id_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 id_specification

  # given: synopsis

  $app->id_specification;

  # [['zing', 'i-d'], [@args]]

=cut

=method journal

The journal method returns a new L<Zing::Journal> object based on the currenrt C<env>.

=signature journal

journal(Any @args) : Journal

=example-1 journal

  # given: synopsis

  my $journal = $app->journal;

  # Zing::Journal->new

=cut

=method journal_namespace

The journal_namespace method returns a wordlist that represents a I<journal>
class name.

=signature journal_namespace

journal_namespace() : ArrayRef[Str]

=example-1 journal_namespace

  # given: synopsis

  $app->journal_namespace;

  # ['zing', 'journal']

=cut

=method journal_specification

The journal_specification method returns a I<journal> specification, class name
and args, for the reifier.

=signature journal_specification

journal_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 journal_specification

  # given: synopsis

  $app->journal_specification;

  # [['zing', 'journal'], [@args]]

=cut

=method kernel

The kernel method returns a new L<Zing::Kernel> object based on the current C<env>.

=signature kernel

kernel(Any @args) : Kernel

=example-1 kernel

  # given: synopsis

  my $kernel = $app->kernel(
    scheme => ['MyApp', [], 1],
  );

  # Zing::Kernel->new(...)

=cut

=method kernel_namespace

The kernel_namespace method returns a wordlist that represents a I<kernel>
class name.

=signature kernel_namespace

kernel_namespace() : ArrayRef[Str]

=example-1 kernel_namespace

  # given: synopsis

  $app->kernel_namespace;

  # ['zing', 'kernel']

=cut

=method kernel_specification

The kernel_specification method returns a I<kernel> specification, class name
and args, for the reifier.

=signature kernel_specification

kernel_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 kernel_specification

  # given: synopsis

  $app->kernel_specification;

  # [['zing', 'kernel'], [@args]]

=cut

=method keyval

The keyval method returns a new L<Zing::KeyVal> object based on the currenrt C<env>.

=signature keyval

keyval(Any @args) : KeyVal

=example-1 keyval

  # given: synopsis

  my $keyval = $app->keyval(
    name => 'backup',
  );

  # Zing::KeyVal->new(...)

=cut

=method keyval_namespace

The keyval_namespace method returns a wordlist that represents a I<keyval>
class name.

=signature keyval_namespace

keyval_namespace() : ArrayRef[Str]

=example-1 keyval_namespace

  # given: synopsis

  $app->keyval_namespace;

  # ['zing', 'key-val']

=cut

=method keyval_specification

The keyval_specification method returns a I<keyval> specification, class name
and args, for the reifier.

=signature keyval_specification

keyval_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 keyval_specification

  # given: synopsis

  $app->keyval_specification;

  # [['zing', 'key-val'], [@args]]

=cut

=method launcher

The launcher method returns a new L<Zing::Launcher> object based on the currenrt C<env>.

=signature launcher

launcher(Any @args) : Launcher

=example-1 launcher

  # given: synopsis

  my $launcher = $app->launcher;

  # Zing::Launcher->new(...)

=cut

=method launcher_namespace

The launcher_namespace method returns a wordlist that represents a I<launcher>
class name.

=signature launcher_namespace

launcher_namespace() : ArrayRef[Str]

=example-1 launcher_namespace

  # given: synopsis

  $app->launcher_namespace;

  # ['zing', 'launcher']

=cut

=method launcher_specification

The launcher_specification method returns a I<launcher> specification, class
name and args, for the reifier.

=signature launcher_specification

launcher_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 launcher_specification

  # given: synopsis

  $app->launcher_specification;

  # [['zing', 'launcher'], [@args]]

=cut

=method logger

The logger method returns a new L<FlightRecorder> object based on the currenrt C<env>.

=signature logger

logger(Any @args) : Logger

=example-1 logger

  # given: synopsis

  my $logger = $app->logger;

  # FlightRecorder->new(...)

=cut

=method lookup

The lookup method returns a new L<Zing::Lookup> object based on the currenrt C<env>.

=signature lookup

lookup(Any @args) : Lookup

=example-1 lookup

  # given: synopsis

  my $lookup = $app->lookup(
    name => 'people',
  );

  # Zing::Lookup->new(...)

=cut

=method lookup_namespace

The lookup_namespace method returns a wordlist that represents a I<lookup>
class name.

=signature lookup_namespace

lookup_namespace() : ArrayRef[Str]

=example-1 lookup_namespace

  # given: synopsis

  $app->lookup_namespace;

  # ['zing', 'lookup']

=cut

=method lookup_specification

The lookup_specification method returns a I<lookup> specification, class name
and args, for the reifier.

=signature lookup_specification

lookup_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 lookup_specification

  # given: synopsis

  $app->lookup_specification;

  # [['zing', 'lookup'], [@args]]

=cut

=method mailbox

The mailbox method returns a new L<Zing::Mailbox> object based on the currenrt C<env>.

=signature mailbox

mailbox(Any @args) : Mailbox

=example-1 mailbox

  # given: synopsis

  my $mailbox = $app->mailbox(
    name => 'shared',
  );

  # Zing::Mailbox->new(...)

=cut

=method mailbox_namespace

The mailbox_namespace method returns a wordlist that represents a I<mailbox>
class name.

=signature mailbox_namespace

mailbox_namespace() : ArrayRef[Str]

=example-1 mailbox_namespace

  # given: synopsis

  $app->mailbox_namespace;

  # ['zing', 'mailbox']

=cut

=method mailbox_specification

The mailbox_specification method returns a I<mailbox> specification, class name
and args, for the reifier.

=signature mailbox_specification

mailbox_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 mailbox_specification

  # given: synopsis

  $app->mailbox_specification;

  # [['zing', 'mailbox'], [@args]]

=cut

=method meta

The meta method returns a new L<Zing::Meta> object based on the currenrt C<env>.

=signature meta

meta(Any @args) : Meta

=example-1 meta

  # given: synopsis

  my $meta = $app->meta(
    name => rand,
  );

  # Zing::Meta->new(...)

=cut

=method meta_namespace

The meta_namespace method returns a wordlist that represents a I<meta> class
name.

=signature meta_namespace

meta_namespace() : ArrayRef[Str]

=example-1 meta_namespace

  # given: synopsis

  $app->meta_namespace;

  # ['zing', 'meta']

=cut

=method meta_specification

The meta_specification method returns a I<meta> specification, class name and
args, for the reifier.

=signature meta_specification

meta_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 meta_specification

  # given: synopsis

  $app->meta_specification;

  # [['zing', 'meta'], [@args]]

=cut

=method process

The process method returns a new L<Zing::Process> object based on the currenrt C<env>.

=signature process

process(Any @args) : Process

=example-1 process

  # given: synopsis

  my $process = $app->process;

  # Zing::Process->new(...)

=cut

=method process_namespace

The process_namespace method returns a wordlist that represents a I<process>
class name.

=signature process_namespace

process_namespace() : ArrayRef[Str]

=example-1 process_namespace

  # given: synopsis

  $app->process_namespace;

  # ['zing', 'process']

=cut

=method process_specification

The process_specification method returns a I<process> specification, class name
and args, for the reifier.

=signature process_specification

process_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 process_specification

  # given: synopsis

  $app->process_specification;

  # [['zing', 'process'], [@args]]

=cut

=method pubsub

The pubsub method returns a new L<Zing::PubSub> object based on the currenrt C<env>.

=signature pubsub

pubsub(Any @args) : PubSub

=example-1 pubsub

  # given: synopsis

  my $pubsub = $app->pubsub(
    name => 'commands',
  );

  # Zing::PubSub->new(...)

=cut

=method pubsub_namespace

The pubsub_namespace method returns a wordlist that represents a I<pubsub>
class name.

=signature pubsub_namespace

pubsub_namespace() : ArrayRef[Str]

=example-1 pubsub_namespace

  # given: synopsis

  $app->pubsub_namespace;

  # ['zing', 'pub-sub']

=cut

=method pubsub_specification

the pubsub_specification method returns a i<pubsub> specification, class name
and args, for the reifier.

=signature pubsub_specification

pubsub_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 pubsub_specification

  # given: synopsis

  $app->pubsub_specification;

  # [['zing', 'pub-sub'], [@args]]

=cut

=method queue

The queue method returns a new L<Zing::Queue> object based on the currenrt C<env>.

=signature queue

queue(Any @args) : Queue

=example-1 queue

  # given: synopsis

  my $queue = $app->queue(
    name => 'tasks',
  );

  # Zing::Queue->new(...)

=cut

=method queue_namespace

The queue_namespace method returns a wordlist that represents a I<queue> class
name.

=signature queue_namespace

queue_namespace() : ArrayRef[Str]

=example-1 queue_namespace

  # given: synopsis

  $app->queue_namespace;

  # ['zing', 'queue']

=cut

=method queue_specification

The queue_specification method returns a I<queue> specification, class name and
args, for the reifier.

=signature queue_specification

queue_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 queue_specification

  # given: synopsis

  $app->queue_specification;

  # [['zing', 'queue'], [@args]]

=cut

=method reify

The reify method executes a specification, reifies and returns an object.

=signature reify

reify(Tuple[ArrayRef, ArrayRef] $spec) : Object

=example-1 reify

  # given: synopsis

  my $queue = $app->reify(
    [['zing', 'queue'], ['name', 'tasks']],
  );

  # Zing::Queue->new(
  #   name => 'tasks'
  # )

=cut

=method repo

The repo method returns a new L<Zing::Repo> object based on the currenrt C<env>.

=signature repo

repo(Any @args) : Repo

=example-1 repo

  # given: synopsis

  my $repo = $app->repo(
    name => '$registry',
  );

  # Zing::Repo->new(...)

=cut

=method repo_namespace

The repo_namespace method returns a wordlist that represents a I<repo> class
name.

=signature repo_namespace

repo_namespace() : ArrayRef[Str]

=example-1 repo_namespace

  # given: synopsis

  $app->repo_namespace;

  # ['zing', 'repo']

=cut

=method repo_specification

The repo_specification method returns a I<repo> specification, class name and
args, for the reifier.

=signature repo_specification

repo_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 repo_specification

  # given: synopsis

  $app->repo_specification;

  # [['zing', 'repo'], [@args]]

=cut

=method ring

The ring method returns a new L<Zing::Ring> object based on the currenrt C<env>.

=signature ring

ring(Any @args) : Ring

=example-1 ring

  # given: synopsis

  my $ring = $app->ring(
    processes => [
      $app->process,
      $app->process,
    ],
  );

  # Zing::Ring->new(...)

=cut

=method ring_namespace

The ring_namespace method returns a wordlist that represents a I<ring> class
name.

=signature ring_namespace

ring_namespace() : ArrayRef[Str]

=example-1 ring_namespace

  # given: synopsis

  $app->ring_namespace;

  # ['zing', 'ring']

=cut

=method ring_specification

The ring_specification method returns a I<ring> specification, class name and
args, for the reifier.

=signature ring_specification

ring_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 ring_specification

  # given: synopsis

  $app->ring_specification;

  # [['zing', 'ring'], [@args]]

=cut

=method ringer

The ringer method returns a new L<Zing::Ringer> object based on the currenrt C<env>.

=signature ringer

ringer(Any @args) : Ring

=example-1 ringer

  # given: synopsis

  my $ringer = $app->ringer(
    schemes => [
      ['MyApp1', [], 1],
      ['MyApp2', [], 1],
    ],
  );

  # Zing::Ringer->new(...)

=cut

=method ringer_namespace

The ringer_namespace method returns a wordlist that represents a I<ringer>
class name.

=signature ringer_namespace

ringer_namespace() : ArrayRef[Str]

=example-1 ringer_namespace

  # given: synopsis

  $app->ringer_namespace;

  # ['zing', 'ringer']

=cut

=method ringer_specification

The ringer_specification method returns a I<ringer> specification, class name
and args, for the reifier.

=signature ringer_specification

ringer_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 ringer_specification

  # given: synopsis

  $app->ringer_specification;

  # [['zing', 'ringer'], [@args]]

=cut

=method savepoint

The savepoint method returns a new L<Zing::Savepoint> object based on the currenrt C<env>.

=signature savepoint

savepoint(Any @args) : Savepoint

=example-1 savepoint

  # given: synopsis

  my $savepoint = $app->savepoint(
    lookup => $app->lookup(
      name => 'people',
    )
  );

  # Zing::Savepoint->new(...)

=cut

=method savepoint_namespace

The savepoint_namespace method returns a wordlist that represents a
I<savepoint> class name.

=signature savepoint_namespace

savepoint_namespace() : ArrayRef[Str]

=example-1 savepoint_namespace

  # given: synopsis

  $app->savepoint_namespace;

  # ['zing', 'savepoint']

=cut

=method savepoint_specification

The savepoint_specification method returns a I<savepoint> specification, class
name and args, for the reifier.

=signature savepoint_specification

savepoint_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 savepoint_specification

  # given: synopsis

  $app->savepoint_specification;

  # [['zing', 'savepoint'], [@args]]

=cut

=method scheduler

The scheduler method returns a new L<Zing::Scheduler> object based on the currenrt C<env>.

=signature scheduler

scheduler(Any @args) : Scheduler

=example-1 scheduler

  # given: synopsis

  my $scheduler = $app->scheduler;

  # Zing::Scheduler->new(...)

=cut

=method scheduler_namespace

The scheduler_namespace method returns a wordlist that represents a
I<scheduler> class name.

=signature scheduler_namespace

scheduler_namespace() : ArrayRef[Str]

=example-1 scheduler_namespace

  # given: synopsis

  $app->scheduler_namespace;

  # ['zing', 'scheduler']

=cut

=method scheduler_specification

The scheduler_specification method returns a I<scheduler> specification, class
name and args, for the reifier.

=signature scheduler_specification

scheduler_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 scheduler_specification

  # given: synopsis

  $app->scheduler_specification;

  # [['zing', 'scheduler'], [@args]]

=cut

=method search

The search method returns a new L<Zing::Search> object based on the currenrt C<env>.

=signature search

search(Any @args) : Search

=example-1 search

  # given: synopsis

  my $search = $app->search;

  # Zing::Search->new(...)

=cut

=method search_namespace

The search_namespace method returns a wordlist that represents a I<search>
class name.

=signature search_namespace

search_namespace() : ArrayRef[Str]

=example-1 search_namespace

  # given: synopsis

  $app->search_namespace;

  # ['zing', 'search']

=cut

=method search_specification

The search_specification method returns a I<search> specification, class name
and args, for the reifier.

=signature search_specification

search_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 search_specification

  # given: synopsis

  $app->search_specification;

  # [['zing', 'search'], [@args]]

=cut

=method simple

The simple method returns a new L<Zing::Simple> object based on the currenrt C<env>.

=signature simple

simple(Any @args) : Simple

=example-1 simple

  # given: synopsis

  my $simple = $app->simple;

  # Zing::Simple->new(...)

=cut

=method simple_namespace

The simple_namespace method returns a wordlist that represents a I<simple>
class name.

=signature simple_namespace

simple_namespace() : ArrayRef[Str]

=example-1 simple_namespace

  # given: synopsis

  $app->simple_namespace;

  # ['zing', 'simple']

=cut

=method simple_specification

The simple_specification method returns a I<simple> specification, class name
and args, for the reifier.

=signature simple_specification

simple_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 simple_specification

  # given: synopsis

  $app->simple_specification;

  # [['zing', 'simple'], [@args]]

=cut

=method single

The single method returns a new L<Zing::Single> object based on the currenrt C<env>.

=signature single

single(Any @args) : Single

=example-1 single

  # given: synopsis

  my $single = $app->single;

  # Zing::Single->new(...)

=cut

=method single_namespace

The single_namespace method returns a wordlist that represents a I<single>
class name.

=signature single_namespace

single_namespace() : ArrayRef[Str]

=example-1 single_namespace

  # given: synopsis

  $app->single_namespace;

  # ['zing', 'single']

=cut

=method single_specification

The single_specification method returns a I<single> specification, class name
and args, for the reifier.

=signature single_specification

single_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 single_specification

  # given: synopsis

  $app->single_specification;

  # [['zing', 'single'], [@args]]

=cut

=method space

The space method returns a new L<Data::Object::Space> object.

=signature space

space(Str @args) : Space

=example-1 space

  # given: synopsis

  my $space = $app->space(
    'zing',
  );

  # Data::Object::Space->new(...)

=cut

=method spawner

The spawner method returns a new L<Zing::Spawner> object based on the currenrt C<env>.

=signature spawner

spawner(Any @args) : Spawner

=example-1 spawner

  # given: synopsis

  my $spawner = $app->spawner;

  # Zing::Spawner->new(...)

=cut

=method spawner_namespace

The spawner_namespace method returns a wordlist that represents a I<spawner>
class name.

=signature spawner_namespace

spawner_namespace() : ArrayRef[Str]

=example-1 spawner_namespace

  # given: synopsis

  $app->spawner_namespace;

  # ['zing', 'spawner']

=cut

=method spawner_specification

The spawner_specification method returns a I<spawner> specification, class name
and args, for the reifier.

=signature spawner_specification

spawner_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 spawner_specification

  # given: synopsis

  $app->spawner_specification;

  # [['zing', 'spawner'], [@args]]

=cut

=method store

The store method returns a new L<Zing::Store> object based on the currenrt C<env>.

=signature store

store(Any @args) : Store

=example-1 store

  # given: synopsis

  my $store = $app->store;

  # Zing::Store::Hash->new(...)

  # e.g.
  # $app->env->store # Zing::Store::Hash

  # e.g.
  # $ENV{ZING_STORE} # Zing::Store::Hash

=cut

=method store_namespace

The store_namespace method returns a wordlist that represents a I<store> class
name.

=signature store_namespace

store_namespace() : ArrayRef[Str]

=example-1 store_namespace

  # given: synopsis

  $app->store_namespace;

  # $ENV{ZING_STORE}

=cut

=method store_specification

The store_specification method returns a I<store> specification, class name and
args, for the reifier.

=signature store_specification

store_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 store_specification

  # given: synopsis

  $app->store_specification;

  # [['zing', 'store'], [@args]]

=cut

=method term

The term method returns a new L<Zing::Term> object based on the currenrt C<env>.

=signature term

term(Any @args) : Term

=example-1 term

  # given: synopsis

  my $term = $app->term(
    $app->process,
  );

  # Zing::Term->new(...)

=cut

=method timer

The timer method returns a new L<Zing::Timer> object based on the currenrt C<env>.

=signature timer

timer(Any @args) : Timer

=example-1 timer

  # given: synopsis

  my $timer = $app->timer;

  # Zing::Timer->new(...)

=cut

=method timer_namespace

The timer_namespace method returns a wordlist that represents a I<timer> class
name.

=signature timer_namespace

timer_namespace() : ArrayRef[Str]

=example-1 timer_namespace

  # given: synopsis

  $app->timer_namespace;

  # ['zing', 'timer']

=cut

=method timer_specification

The timer_specification method returns a I<timer> specification, class name and
args, for the reifier.

=signature timer_specification

timer_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 timer_specification

  # given: synopsis

  $app->timer_specification;

  # [['zing', 'timer'], [@args]]

=cut

=method watcher

The watcher method returns a new L<Zing::Watcher> object based on the currenrt C<env>.

=signature watcher

watcher(Any @args) : Watcher

=example-1 watcher

  # given: synopsis

  my $watcher = $app->watcher;

  # Zing::Watcher->new(...)

=cut

=method watcher_namespace

The watcher_namespace method returns a wordlist that represents a I<watcher>
class name.

=signature watcher_namespace

watcher_namespace() : ArrayRef[Str]

=example-1 watcher_namespace

  # given: synopsis

  $app->watcher_namespace;

  # ['zing', 'watcher']

=cut

=method watcher_specification

The watcher_specification method returns a I<watcher> specification, class name
and args, for the reifier.

=signature watcher_specification

watcher_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 watcher_specification

  # given: synopsis

  $app->watcher_specification;

  # [['zing', 'watcher'], [@args]]

=cut

=method worker

The worker method returns a new L<Zing::Worker> object based on the currenrt C<env>.

=signature worker

worker(Any @args) : Worker

=example-1 worker

  # given: synopsis

  my $worker = $app->worker;

  # Zing::Worker->new(...)

=cut

=method worker_namespace

The worker_namespace method returns a wordlist that represents a I<worker>
class name.

=signature worker_namespace

worker_namespace() : ArrayRef[Str]

=example-1 worker_namespace

  # given: synopsis

  $app->worker_namespace;

  # ['zing', 'worker']

=cut

=method worker_specification

The worker_specification method returns a I<worker> specification, class name
and args, for the reifier.

=signature worker_specification

worker_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

=example-1 worker_specification

  # given: synopsis

  $app->worker_specification;

  # [['zing', 'worker'], [@args]]

=cut

=method zang

The zang method returns a new L<Zing::Zang> object.

=signature zang

zang() : App

=example-1 zang

  # given: synopsis

  $app = $app->zang;

  # Zing::App->new(name => 'zing/zang')

=cut

=method zing

The zing method returns a new L<Zing> object.

=signature zing

zing(Any @args) : Zing

=example-1 zing

  # given: synopsis

  my $zing = $app->zing(
    scheme => ['MyApp', [], 1],
  );

  # Zing->new(...)

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'for', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'cartridge', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'cartridge_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'cartridge'];

  $result
});

$subs->example(-1, 'cartridge_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'cartridge'], []];

  $result
});

$subs->example(-1, 'channel', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'channel_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'channel'];

  $result
});

$subs->example(-1, 'channel_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'channel'], []];

  $result
});

$subs->example(-1, 'cursor', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'cursor_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'cursor'];

  $result
});

$subs->example(-1, 'cursor_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'cursor'], []];

  $result
});

$subs->example(-1, 'daemon', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'daemon_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'daemon'];

  $result
});

$subs->example(-1, 'daemon_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'daemon'], []];

  $result
});

$subs->example(-1, 'data', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'data_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'data'];

  $result
});

$subs->example(-1, 'data_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'data'], []];

  $result
});

$subs->example(-1, 'domain', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'domain_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'domain'];

  $result
});

$subs->example(-1, 'domain_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'domain'], []];

  $result
});

$subs->example(-1, 'encoder', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'encoder_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [$ENV{ZING_ENCODER} || 'Zing::Encoder::Dump'];

  $result
});

$subs->example(-1, 'encoder_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [[$ENV{ZING_ENCODER} || 'Zing::Encoder::Dump'], []];

  $result
});

$subs->example(-1, 'fork', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'fork_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'fork'];

  $result
});

$subs->example(-1, 'fork_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'fork'], []];

  $result
});

$subs->example(-1, 'id', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'id_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'i-d'];

  $result
});

$subs->example(-1, 'id_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'i-d'], []];

  $result
});

$subs->example(-1, 'journal', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'journal_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'journal'];

  $result
});

$subs->example(-1, 'journal_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'journal'], []];

  $result
});

$subs->example(-1, 'kernel', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'kernel_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'kernel'];

  $result
});

$subs->example(-1, 'kernel_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'kernel'], []];

  $result
});

$subs->example(-1, 'keyval', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'keyval_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'key-val'];

  $result
});

$subs->example(-1, 'keyval_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'key-val'], []];

  $result
});

$subs->example(-1, 'launcher', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'launcher_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'launcher'];

  $result
});

$subs->example(-1, 'launcher_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'launcher'], []];

  $result
});

$subs->example(-1, 'logger', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'lookup', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'lookup_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'lookup'];

  $result
});

$subs->example(-1, 'lookup_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'lookup'], []];

  $result
});

$subs->example(-1, 'mailbox', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'mailbox_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'mailbox'];

  $result
});

$subs->example(-1, 'mailbox_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'mailbox'], []];

  $result
});

$subs->example(-1, 'meta', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'meta_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'meta'];

  $result
});

$subs->example(-1, 'meta_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'meta'], []];

  $result
});

$subs->example(-1, 'process', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'process_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'process'];

  $result
});

$subs->example(-1, 'process_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'process'], []];

  $result
});

$subs->example(-1, 'pubsub', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'pubsub_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'pub-sub'];

  $result
});

$subs->example(-1, 'pubsub_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'pub-sub'], []];

  $result
});

$subs->example(-1, 'queue', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'queue_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'queue'];

  $result
});

$subs->example(-1, 'queue_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'queue'], []];

  $result
});

$subs->example(-1, 'reify', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'repo', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'repo_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'repo'];

  $result
});

$subs->example(-1, 'repo_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'repo'], []];

  $result
});

$subs->example(-1, 'ring', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'ring_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'ring'];

  $result
});

$subs->example(-1, 'ring_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'ring'], []];

  $result
});

$subs->example(-1, 'ringer', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'ringer_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'ringer'];

  $result
});

$subs->example(-1, 'ringer_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'ringer'], []];

  $result
});

$subs->example(-1, 'savepoint', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'savepoint_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'savepoint'];

  $result
});

$subs->example(-1, 'savepoint_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'savepoint'], []];

  $result
});

$subs->example(-1, 'scheduler', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'scheduler_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'scheduler'];

  $result
});

$subs->example(-1, 'scheduler_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'scheduler'], []];

  $result
});

$subs->example(-1, 'search', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'search_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'search'];

  $result
});

$subs->example(-1, 'search_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'search'], []];

  $result
});

$subs->example(-1, 'simple', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'simple_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'simple'];

  $result
});

$subs->example(-1, 'simple_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'simple'], []];

  $result
});

$subs->example(-1, 'single', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'single_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'single'];

  $result
});

$subs->example(-1, 'single_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'single'], []];

  $result
});

$subs->example(-1, 'space', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'spawner', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'spawner_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'spawner'];

  $result
});

$subs->example(-1, 'spawner_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'spawner'], []];

  $result
});

$subs->example(-1, 'store', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'store_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [$ENV{ZING_STORE} || 'Test::Zing::Store'];

  $result
});

$subs->example(-1, 'store_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->[0][0],
    $ENV{ZING_STORE} || 'Test::Zing::Store';
  is $result->[1][0],
    'encoder';
  is ref($result->[1][1]),
    $ENV{ZING_ENCODER} || 'Zing::Encoder::Dump';

  $result
});

$subs->example(-1, 'term', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'timer', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'timer_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'timer'];

  $result
});

$subs->example(-1, 'timer_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'timer'], []];

  $result
});

$subs->example(-1, 'watcher', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'watcher_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'watcher'];

  $result
});

$subs->example(-1, 'watcher_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'watcher'], []];

  $result
});

$subs->example(-1, 'worker', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'worker_namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['zing', 'worker'];

  $result
});

$subs->example(-1, 'worker_specification', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [['zing', 'worker'], []];

  $result
});

$subs->example(-1, 'zang', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'zing', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
