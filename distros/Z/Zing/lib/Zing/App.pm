package Zing::App;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;
use Data::Object::Space;

our $VERSION = '0.25'; # VERSION

# ATTRIBUTES

has env => (
  is => 'ro',
  isa => 'Env',
  new => 1,
);

fun new_env($self) {
  require Zing::Env; Zing::Env->new(app => $self);
}

has host => (
  is => 'ro',
  isa => 'Str',
  init_arg => undef,
  new => 1,
);

fun new_host($self) {
  $self->env->host
}

has name => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_name($self) {
  'zing'
}

has pid => (
  is => 'ro',
  isa => 'Int',
  init_arg => undef,
  new => 1,
);

fun new_pid($self) {
  $$
}

# METHODS

method for(Any %args) {
  my %data = %{$self->env}; delete $data{app};
  require Zing::Env; Zing::Env->new(%data, %args)->app;
}

method cartridge(Any @args) {
  return $self->reify($self->cartridge_specification(@args));
}

method cartridge_namespace() {
  return [$self->name, 'cartridge'];
}

method cartridge_specification(Any @args) {
  return [$self->cartridge_namespace, [@args]];
}

method channel(Any @args) {
  return $self->reify($self->channel_specification(@args));
}

method channel_namespace() {
  return [$self->name, 'channel'];
}

method channel_specification(Any @args) {
  return [$self->channel_namespace, [@args]];
}

method cursor(Any @args) {
  return $self->reify($self->cursor_specification(@args));
}

method cursor_namespace() {
  return [$self->name, 'cursor'];
}

method cursor_specification(Any @args) {
  return [$self->cursor_namespace, [@args]];
}

method daemon(Any @args) {
  return $self->reify($self->daemon_specification(@args));
}

method daemon_namespace() {
  return [$self->name, 'daemon'];
}

method daemon_specification(Any @args) {
  return [$self->daemon_namespace, [@args]];
}

method data(Any @args) {
  return $self->reify($self->data_specification(@args));
}

method data_namespace() {
  return [$self->name, 'data'];
}

method data_specification(Any @args) {
  return [$self->data_namespace, [@args]];
}

method domain(Any @args) {
  return $self->reify($self->domain_specification(@args));
}

method domain_namespace() {
  return [$self->name, 'domain'];
}

method domain_specification(Any @args) {
  return [$self->domain_namespace, [@args]];
}

method encoder(Any @args) {
  return $self->reify($self->encoder_specification(@args));
}

method encoder_namespace() {
  return [$self->env->encoder];
}

method encoder_specification(Any @args) {
  return [$self->encoder_namespace, [@args]];
}

method fork(Any @args) {
  return $self->reify($self->fork_specification(@args));
}

method fork_namespace() {
  return [$self->name, 'fork'];
}

method fork_specification(Any @args) {
  return [$self->fork_namespace, [@args]];
}

method id(Any @args) {
  return $self->reify($self->id_specification(@args));
}

method id_namespace() {
  return [$self->name, 'i-d'];
}

method id_specification(Any @args) {
  return [$self->id_namespace, [@args]];
}

method journal(Any @args) {
  return $self->reify($self->journal_specification(@args));
}

method journal_namespace() {
  return [$self->name, 'journal'];
}

method journal_specification(Any @args) {
  return [$self->journal_namespace, [@args]];
}

method kernel(Any @args) {
  return $self->reify($self->kernel_specification(@args));
}

method kernel_namespace() {
  return [$self->name, 'kernel'];
}

method kernel_specification(Any @args) {
  return [$self->kernel_namespace, [@args]];
}

method keyval(Any @args) {
  return $self->reify($self->keyval_specification(@args));
}

method keyval_namespace() {
  return [$self->name, 'key-val'];
}

method keyval_specification(Any @args) {
  return [$self->keyval_namespace, [@args]];
}

method launcher(Any @args) {
  return $self->reify($self->launcher_specification(@args));
}

method launcher_namespace() {
  return [$self->name, 'launcher'];
}

method launcher_specification(Any @args) {
  return [$self->launcher_namespace, [@args]];
}

method logger(Any @args) {
  require FlightRecorder; FlightRecorder->new(level => 'info', @args);
}

method lookup(Any @args) {
  return $self->reify($self->lookup_specification(@args));
}

method lookup_namespace() {
  return [$self->name, 'lookup'];
}

method lookup_specification(Any @args) {
  return [$self->lookup_namespace, [@args]];
}

method mailbox(Any @args) {
  return $self->reify($self->mailbox_specification(@args));
}

method mailbox_namespace() {
  return [$self->name, 'mailbox'];
}

method mailbox_specification(Any @args) {
  return [$self->mailbox_namespace, [@args]];
}

method meta(Any @args) {
  return $self->reify($self->meta_specification(@args));
}

method meta_namespace() {
  return [$self->name, 'meta'];
}

method meta_specification(Any @args) {
  return [$self->meta_namespace, [@args]];
}

method process(Any @args) {
  return $self->reify($self->process_specification(@args));
}

method process_namespace() {
  return [$self->name, 'process'];
}

method process_specification(Any @args) {
  return [$self->process_namespace, [@args]];
}

method pubsub(Any @args) {
  return $self->reify($self->pubsub_specification(@args));
}

method pubsub_namespace() {
  return [$self->name, 'pub-sub'];
}

method pubsub_specification(Any @args) {
  return [$self->pubsub_namespace, [@args]];
}

method queue(Any @args) {
  return $self->reify($self->queue_specification(@args));
}

method queue_namespace() {
  return [$self->name, 'queue'];
}

method queue_specification(Any @args) {
  return [$self->queue_namespace, [@args]];
}

method reify(Tuple[ArrayRef, ArrayRef] $spec) {
  return $self->space(@{$spec->[0]})->build(@{$spec->[1]}, env => $self->env);
}

method repo(Any @args) {
  return $self->reify($self->repo_specification(@args));
}

method repo_namespace() {
  return [$self->name, 'repo'];
}

method repo_specification(Any @args) {
  return [$self->repo_namespace, [@args]];
}

method ring(Any @args) {
  return $self->reify($self->ring_specification(@args));
}

method ring_namespace() {
  return [$self->name, 'ring'];
}

method ring_specification(Any @args) {
  return [$self->ring_namespace, [@args]];
}

method ringer(Any @args) {
  return $self->reify($self->ringer_specification(@args));
}

method ringer_namespace() {
  return [$self->name, 'ringer'];
}

method ringer_specification(Any @args) {
  return [$self->ringer_namespace, [@args]];
}

method savepoint(Any @args) {
  return $self->reify($self->savepoint_specification(@args));
}

method savepoint_namespace() {
  return [$self->name, 'savepoint'];
}

method savepoint_specification(Any @args) {
  return [$self->savepoint_namespace, [@args]];
}

method scheduler(Any @args) {
  return $self->reify($self->scheduler_specification(@args));
}

method scheduler_namespace() {
  return [$self->name, 'scheduler'];
}

method scheduler_specification(Any @args) {
  return [$self->scheduler_namespace, [@args]];
}

method search(Any @args) {
  return $self->reify($self->search_specification(@args));
}

method search_namespace() {
  return [$self->name, 'search'];
}

method search_specification(Any @args) {
  return [$self->search_namespace, [@args]];
}

method simple(Any @args) {
  return $self->reify($self->simple_specification(@args));
}

method simple_namespace() {
  return [$self->name, 'simple'];
}

method simple_specification(Any @args) {
  return [$self->simple_namespace, [@args]];
}

method single(Any @args) {
  return $self->reify($self->single_specification(@args));
}

method single_namespace() {
  return [$self->name, 'single'];
}

method single_specification(Any @args) {
  return [$self->single_namespace, [@args]];
}

method space(Str @args) {
  return Data::Object::Space->new(join '/', (@args ? @args : $self->name));
}

method spawner(Any @args) {
  return $self->reify($self->spawner_specification(@args));
}

method spawner_namespace() {
  return [$self->name, 'spawner'];
}

method spawner_specification(Any @args) {
  return [$self->spawner_namespace, [@args]];
}

method store(Any @args) {
  return $self->reify($self->store_specification(@args));
}

method store_namespace() {
  return [$self->env->store];
}

method store_specification(Any @args) {
  return [$self->store_namespace, [encoder => $self->encoder, @args]];
}

method table(Any @args) {
  return $self->reify($self->table_specification(@args));
}

method table_namespace() {
  return [$self->name, 'table'];
}

method table_specification(Any @args) {
  return [$self->table_namespace, [@args]];
}

method term(Any @args) {
  require Zing::Term; Zing::Term->new(@args);
}

method timer(Any @args) {
  return $self->reify($self->timer_specification(@args));
}

method timer_namespace() {
  return [$self->name, 'timer'];
}

method timer_specification(Any @args) {
  return [$self->timer_namespace, [@args]];
}

method watcher(Any @args) {
  return $self->reify($self->watcher_specification(@args));
}

method watcher_namespace() {
  return [$self->name, 'watcher'];
}

method watcher_specification(Any @args) {
  return [$self->watcher_namespace, [@args]];
}

method worker(Any @args) {
  return $self->reify($self->worker_specification(@args));
}

method worker_namespace() {
  return [$self->name, 'worker'];
}

method worker_specification(Any @args) {
  return [$self->worker_namespace, [@args]];
}

method zang() {
  return ref($self)->new(name => 'Zing/Zang');
}

method zing(Any @args) {
  require Zing; Zing->new(@args);
}

1;

=encoding utf8

=head1 NAME

Zing::App - Object Reifier

=cut

=head1 ABSTRACT

Object Reifier with Dependency Injection

=cut

=head1 SYNOPSIS

  use Zing::App;

  my $app = Zing::App->new;

  # $app->queue(name => 'tasks')->send({
  #   job => time,
  #   ...
  # });

=cut

=head1 DESCRIPTION

This package provides an object which can dynamically load (reify) other
L<Zing> objects with dependencies.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 env

  env(Env)

This attribute is read-only, accepts C<(Env)> values, and is optional.

=cut

=head2 host

  host(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 name

  name(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 pid

  pid(Int)

This attribute is read-only, accepts C<(Int)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 cartridge

  cartridge(Any @args) : Cartridge

The cartridge method returns a new L<Zing::Cartridge> object based on the current C<env>.

=over 4

=item cartridge example #1

  # given: synopsis

  my $cartridge = $app->cartridge(
    name => 'myapp',
  );

  # Zing::Cartridge->new(...)

=back

=cut

=head2 cartridge_namespace

  cartridge_namespace() : ArrayRef[Str]

The cartridge_namespace method returns a wordlist that represents a
I<cartridge> class name.

=over 4

=item cartridge_namespace example #1

  # given: synopsis

  $app->cartridge_namespace;

  # ['zing', 'cartridge']

=back

=cut

=head2 cartridge_specification

  cartridge_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The cartridge_specification method returns a I<cartridge> specification, class
name and args, for the reifier.

=over 4

=item cartridge_specification example #1

  # given: synopsis

  $app->cartridge_specification;

  # [['zing', 'cartridge'], [@args]]

=back

=cut

=head2 channel

  channel(Any @args) : Channel

The channel method returns a new L<Zing::Channel> object based on the currenrt C<env>.

=over 4

=item channel example #1

  # given: synopsis

  my $channel = $app->channel(
    name => 'messages',
  );

  # Zing::Channel->new(...)

=back

=cut

=head2 channel_namespace

  channel_namespace() : ArrayRef[Str]

The channel_namespace method returns a wordlist that represents a I<channel>
class name.

=over 4

=item channel_namespace example #1

  # given: synopsis

  $app->channel_namespace;

  # ['zing', 'channel']

=back

=cut

=head2 channel_specification

  channel_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The channel_specification method returns a I<channel> specification, class name
and args, for the reifier.

=over 4

=item channel_specification example #1

  # given: synopsis

  $app->channel_specification;

  # [['zing', 'channel'], [@args]]

=back

=cut

=head2 cursor

  cursor(Any @args) : Cursor

The cursor method returns a new L<Zing::Cursor> object based on the current C<env>.

=over 4

=item cursor example #1

  # given: synopsis

  my $cursor = $app->cursor(
    lookup => $app->lookup(
      name => 'people',
    )
  );

  # Zing::Cursor->new(...)

=back

=cut

=head2 cursor_namespace

  cursor_namespace() : ArrayRef[Str]

The cursor_namespace method returns a wordlist that represents a I<cursor>
class name.

=over 4

=item cursor_namespace example #1

  # given: synopsis

  $app->cursor_namespace;

  # ['zing', 'cursor']

=back

=cut

=head2 cursor_specification

  cursor_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The cursor_specification method returns a I<cursor> specification, class name
and args, for the reifier.

=over 4

=item cursor_specification example #1

  # given: synopsis

  $app->cursor_specification;

  # [['zing', 'cursor'], [@args]]

=back

=cut

=head2 daemon

  daemon(Any @args) : Daemon

The daemon method returns a new L<Zing::Daemon> object based on the currenrt C<env>.

=over 4

=item daemon example #1

  # given: synopsis

  my $daemon = $app->daemon(
    cartridge => $app->cartridge(
      name => 'myapp',
    )
  );

  # Zing::Daemon->new(...)

=back

=cut

=head2 daemon_namespace

  daemon_namespace() : ArrayRef[Str]

The daemon_namespace method returns a wordlist that represents a I<daemon>
class name.

=over 4

=item daemon_namespace example #1

  # given: synopsis

  $app->daemon_namespace;

  # ['zing', 'daemon']

=back

=cut

=head2 daemon_specification

  daemon_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The daemon_specification method returns a I<daemon> specification, class name
and args, for the reifier.

=over 4

=item daemon_specification example #1

  # given: synopsis

  $app->daemon_specification;

  # [['zing', 'daemon'], [@args]]

=back

=cut

=head2 data

  data(Any @args) : Data

The data method returns a new L<Zing::Data> object based on the current C<env>.

=over 4

=item data example #1

  # given: synopsis

  my $data = $app->data(
    name => 'random',
  );

  # Zing::Data->new(...)

=back

=cut

=head2 data_namespace

  data_namespace() : ArrayRef[Str]

The data_namespace method returns a wordlist that represents a I<data> class
name.

=over 4

=item data_namespace example #1

  # given: synopsis

  $app->data_namespace;

  # ['zing', 'data']

=back

=cut

=head2 data_specification

  data_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The data_specification method returns a I<data> specification, class name and
args, for the reifier.

=over 4

=item data_specification example #1

  # given: synopsis

  $app->data_specification;

  # [['zing', 'data'], [@args]]

=back

=cut

=head2 domain

  domain(Any @args) : Domain

The domain method returns a new L<Zing::Domain> object based on the currenrt C<env>.

=over 4

=item domain example #1

  # given: synopsis

  my $domain = $app->domain(
    name => 'person',
  );

  # Zing::Domain->new(...)

=back

=cut

=head2 domain_namespace

  domain_namespace() : ArrayRef[Str]

The domain_namespace method returns a wordlist that represents a I<domain>
class name.

=over 4

=item domain_namespace example #1

  # given: synopsis

  $app->domain_namespace;

  # ['zing', 'domain']

=back

=cut

=head2 domain_specification

  domain_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The domain_specification method returns a I<domain> specification, class name
and args, for the reifier.

=over 4

=item domain_specification example #1

  # given: synopsis

  $app->domain_specification;

  # [['zing', 'domain'], [@args]]

=back

=cut

=head2 encoder

  encoder(Any @args) : Encoder

The encoder method returns a new L<Zing::Encoder> object based on the current C<env>.

=over 4

=item encoder example #1

  # given: synopsis

  my $encoder = $app->encoder;

  # Zing::Encoder->new

=back

=cut

=head2 encoder_namespace

  encoder_namespace() : ArrayRef[Str]

The encoder_namespace method returns a wordlist that represents a I<encoder>
class name.

=over 4

=item encoder_namespace example #1

  # given: synopsis

  $app->encoder_namespace;

  # ['zing', 'encoder']

=back

=cut

=head2 encoder_specification

  encoder_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The encoder_specification method returns a I<encoder> specification, class name
and args, for the reifier.

=over 4

=item encoder_specification example #1

  # given: synopsis

  $app->encoder_specification;

  # [['zing', 'encoder'], [@args]]

=back

=cut

=head2 for

  for(Any %args) : App

The for method changes the C<env> and returns a new C<app> object.

=over 4

=item for example #1

  # given: synopsis

  $app = $app->for(
    handle => 'myapp',
    target => 'us-east'
  );

=back

=cut

=head2 fork

  fork(Any @args) : Fork

The fork method returns a new L<Zing::Fork> object based on the currenrt C<env>.

=over 4

=item fork example #1

  # given: synopsis

  my $fork = $app->fork(
    parent => $app->process,
    scheme => ['MyApp', [], 1],
  );

  # Zing::Fork->new(...)

=back

=cut

=head2 fork_namespace

  fork_namespace() : ArrayRef[Str]

The fork_namespace method returns a wordlist that represents a I<fork> class
name.

=over 4

=item fork_namespace example #1

  # given: synopsis

  $app->fork_namespace;

  # ['zing', 'fork']

=back

=cut

=head2 fork_specification

  fork_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The fork_specification method returns a I<fork> specification, class name and
args, for the reifier.

=over 4

=item fork_specification example #1

  # given: synopsis

  $app->fork_specification;

  # [['zing', 'fork'], [@args]]

=back

=cut

=head2 id

  id(Any @args) : ID

The id method returns a new L<Zing::ID> object based on the current C<env>.

=over 4

=item id example #1

  # given: synopsis

  my $id = $app->id;

  # Zing::ID->new(...)

=back

=cut

=head2 id_namespace

  id_namespace() : ArrayRef[Str]

The id_namespace method returns a wordlist that represents a I<id> class name.

=over 4

=item id_namespace example #1

  # given: synopsis

  $app->id_namespace;

  # ['zing', 'i-d']

=back

=cut

=head2 id_specification

  id_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The id_specification method returns a I<id> specification, class name and args,
for the reifier.

=over 4

=item id_specification example #1

  # given: synopsis

  $app->id_specification;

  # [['zing', 'i-d'], [@args]]

=back

=cut

=head2 journal

  journal(Any @args) : Journal

The journal method returns a new L<Zing::Journal> object based on the currenrt C<env>.

=over 4

=item journal example #1

  # given: synopsis

  my $journal = $app->journal;

  # Zing::Journal->new

=back

=cut

=head2 journal_namespace

  journal_namespace() : ArrayRef[Str]

The journal_namespace method returns a wordlist that represents a I<journal>
class name.

=over 4

=item journal_namespace example #1

  # given: synopsis

  $app->journal_namespace;

  # ['zing', 'journal']

=back

=cut

=head2 journal_specification

  journal_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The journal_specification method returns a I<journal> specification, class name
and args, for the reifier.

=over 4

=item journal_specification example #1

  # given: synopsis

  $app->journal_specification;

  # [['zing', 'journal'], [@args]]

=back

=cut

=head2 kernel

  kernel(Any @args) : Kernel

The kernel method returns a new L<Zing::Kernel> object based on the current C<env>.

=over 4

=item kernel example #1

  # given: synopsis

  my $kernel = $app->kernel(
    scheme => ['MyApp', [], 1],
  );

  # Zing::Kernel->new(...)

=back

=cut

=head2 kernel_namespace

  kernel_namespace() : ArrayRef[Str]

The kernel_namespace method returns a wordlist that represents a I<kernel>
class name.

=over 4

=item kernel_namespace example #1

  # given: synopsis

  $app->kernel_namespace;

  # ['zing', 'kernel']

=back

=cut

=head2 kernel_specification

  kernel_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The kernel_specification method returns a I<kernel> specification, class name
and args, for the reifier.

=over 4

=item kernel_specification example #1

  # given: synopsis

  $app->kernel_specification;

  # [['zing', 'kernel'], [@args]]

=back

=cut

=head2 keyval

  keyval(Any @args) : KeyVal

The keyval method returns a new L<Zing::KeyVal> object based on the currenrt C<env>.

=over 4

=item keyval example #1

  # given: synopsis

  my $keyval = $app->keyval(
    name => 'backup',
  );

  # Zing::KeyVal->new(...)

=back

=cut

=head2 keyval_namespace

  keyval_namespace() : ArrayRef[Str]

The keyval_namespace method returns a wordlist that represents a I<keyval>
class name.

=over 4

=item keyval_namespace example #1

  # given: synopsis

  $app->keyval_namespace;

  # ['zing', 'key-val']

=back

=cut

=head2 keyval_specification

  keyval_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The keyval_specification method returns a I<keyval> specification, class name
and args, for the reifier.

=over 4

=item keyval_specification example #1

  # given: synopsis

  $app->keyval_specification;

  # [['zing', 'key-val'], [@args]]

=back

=cut

=head2 launcher

  launcher(Any @args) : Launcher

The launcher method returns a new L<Zing::Launcher> object based on the currenrt C<env>.

=over 4

=item launcher example #1

  # given: synopsis

  my $launcher = $app->launcher;

  # Zing::Launcher->new(...)

=back

=cut

=head2 launcher_namespace

  launcher_namespace() : ArrayRef[Str]

The launcher_namespace method returns a wordlist that represents a I<launcher>
class name.

=over 4

=item launcher_namespace example #1

  # given: synopsis

  $app->launcher_namespace;

  # ['zing', 'launcher']

=back

=cut

=head2 launcher_specification

  launcher_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The launcher_specification method returns a I<launcher> specification, class
name and args, for the reifier.

=over 4

=item launcher_specification example #1

  # given: synopsis

  $app->launcher_specification;

  # [['zing', 'launcher'], [@args]]

=back

=cut

=head2 logger

  logger(Any @args) : Logger

The logger method returns a new L<FlightRecorder> object based on the currenrt C<env>.

=over 4

=item logger example #1

  # given: synopsis

  my $logger = $app->logger;

  # FlightRecorder->new(...)

=back

=cut

=head2 lookup

  lookup(Any @args) : Lookup

The lookup method returns a new L<Zing::Lookup> object based on the currenrt C<env>.

=over 4

=item lookup example #1

  # given: synopsis

  my $lookup = $app->lookup(
    name => 'people',
  );

  # Zing::Lookup->new(...)

=back

=cut

=head2 lookup_namespace

  lookup_namespace() : ArrayRef[Str]

The lookup_namespace method returns a wordlist that represents a I<lookup>
class name.

=over 4

=item lookup_namespace example #1

  # given: synopsis

  $app->lookup_namespace;

  # ['zing', 'lookup']

=back

=cut

=head2 lookup_specification

  lookup_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The lookup_specification method returns a I<lookup> specification, class name
and args, for the reifier.

=over 4

=item lookup_specification example #1

  # given: synopsis

  $app->lookup_specification;

  # [['zing', 'lookup'], [@args]]

=back

=cut

=head2 mailbox

  mailbox(Any @args) : Mailbox

The mailbox method returns a new L<Zing::Mailbox> object based on the currenrt C<env>.

=over 4

=item mailbox example #1

  # given: synopsis

  my $mailbox = $app->mailbox(
    name => 'shared',
  );

  # Zing::Mailbox->new(...)

=back

=cut

=head2 mailbox_namespace

  mailbox_namespace() : ArrayRef[Str]

The mailbox_namespace method returns a wordlist that represents a I<mailbox>
class name.

=over 4

=item mailbox_namespace example #1

  # given: synopsis

  $app->mailbox_namespace;

  # ['zing', 'mailbox']

=back

=cut

=head2 mailbox_specification

  mailbox_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The mailbox_specification method returns a I<mailbox> specification, class name
and args, for the reifier.

=over 4

=item mailbox_specification example #1

  # given: synopsis

  $app->mailbox_specification;

  # [['zing', 'mailbox'], [@args]]

=back

=cut

=head2 meta

  meta(Any @args) : Meta

The meta method returns a new L<Zing::Meta> object based on the currenrt C<env>.

=over 4

=item meta example #1

  # given: synopsis

  my $meta = $app->meta(
    name => rand,
  );

  # Zing::Meta->new(...)

=back

=cut

=head2 meta_namespace

  meta_namespace() : ArrayRef[Str]

The meta_namespace method returns a wordlist that represents a I<meta> class
name.

=over 4

=item meta_namespace example #1

  # given: synopsis

  $app->meta_namespace;

  # ['zing', 'meta']

=back

=cut

=head2 meta_specification

  meta_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The meta_specification method returns a I<meta> specification, class name and
args, for the reifier.

=over 4

=item meta_specification example #1

  # given: synopsis

  $app->meta_specification;

  # [['zing', 'meta'], [@args]]

=back

=cut

=head2 process

  process(Any @args) : Process

The process method returns a new L<Zing::Process> object based on the currenrt C<env>.

=over 4

=item process example #1

  # given: synopsis

  my $process = $app->process;

  # Zing::Process->new(...)

=back

=cut

=head2 process_namespace

  process_namespace() : ArrayRef[Str]

The process_namespace method returns a wordlist that represents a I<process>
class name.

=over 4

=item process_namespace example #1

  # given: synopsis

  $app->process_namespace;

  # ['zing', 'process']

=back

=cut

=head2 process_specification

  process_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The process_specification method returns a I<process> specification, class name
and args, for the reifier.

=over 4

=item process_specification example #1

  # given: synopsis

  $app->process_specification;

  # [['zing', 'process'], [@args]]

=back

=cut

=head2 pubsub

  pubsub(Any @args) : PubSub

The pubsub method returns a new L<Zing::PubSub> object based on the currenrt C<env>.

=over 4

=item pubsub example #1

  # given: synopsis

  my $pubsub = $app->pubsub(
    name => 'commands',
  );

  # Zing::PubSub->new(...)

=back

=cut

=head2 pubsub_namespace

  pubsub_namespace() : ArrayRef[Str]

The pubsub_namespace method returns a wordlist that represents a I<pubsub>
class name.

=over 4

=item pubsub_namespace example #1

  # given: synopsis

  $app->pubsub_namespace;

  # ['zing', 'pub-sub']

=back

=cut

=head2 pubsub_specification

  pubsub_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

the pubsub_specification method returns a i<pubsub> specification, class name
and args, for the reifier.

=over 4

=item pubsub_specification example #1

  # given: synopsis

  $app->pubsub_specification;

  # [['zing', 'pub-sub'], [@args]]

=back

=cut

=head2 queue

  queue(Any @args) : Queue

The queue method returns a new L<Zing::Queue> object based on the currenrt C<env>.

=over 4

=item queue example #1

  # given: synopsis

  my $queue = $app->queue(
    name => 'tasks',
  );

  # Zing::Queue->new(...)

=back

=cut

=head2 queue_namespace

  queue_namespace() : ArrayRef[Str]

The queue_namespace method returns a wordlist that represents a I<queue> class
name.

=over 4

=item queue_namespace example #1

  # given: synopsis

  $app->queue_namespace;

  # ['zing', 'queue']

=back

=cut

=head2 queue_specification

  queue_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The queue_specification method returns a I<queue> specification, class name and
args, for the reifier.

=over 4

=item queue_specification example #1

  # given: synopsis

  $app->queue_specification;

  # [['zing', 'queue'], [@args]]

=back

=cut

=head2 reify

  reify(Tuple[ArrayRef, ArrayRef] $spec) : Object

The reify method executes a specification, reifies and returns an object.

=over 4

=item reify example #1

  # given: synopsis

  my $queue = $app->reify(
    [['zing', 'queue'], ['name', 'tasks']],
  );

  # Zing::Queue->new(
  #   name => 'tasks'
  # )

=back

=cut

=head2 repo

  repo(Any @args) : Repo

The repo method returns a new L<Zing::Repo> object based on the currenrt C<env>.

=over 4

=item repo example #1

  # given: synopsis

  my $repo = $app->repo(
    name => '$registry',
  );

  # Zing::Repo->new(...)

=back

=cut

=head2 repo_namespace

  repo_namespace() : ArrayRef[Str]

The repo_namespace method returns a wordlist that represents a I<repo> class
name.

=over 4

=item repo_namespace example #1

  # given: synopsis

  $app->repo_namespace;

  # ['zing', 'repo']

=back

=cut

=head2 repo_specification

  repo_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The repo_specification method returns a I<repo> specification, class name and
args, for the reifier.

=over 4

=item repo_specification example #1

  # given: synopsis

  $app->repo_specification;

  # [['zing', 'repo'], [@args]]

=back

=cut

=head2 ring

  ring(Any @args) : Ring

The ring method returns a new L<Zing::Ring> object based on the currenrt C<env>.

=over 4

=item ring example #1

  # given: synopsis

  my $ring = $app->ring(
    processes => [
      $app->process,
      $app->process,
    ],
  );

  # Zing::Ring->new(...)

=back

=cut

=head2 ring_namespace

  ring_namespace() : ArrayRef[Str]

The ring_namespace method returns a wordlist that represents a I<ring> class
name.

=over 4

=item ring_namespace example #1

  # given: synopsis

  $app->ring_namespace;

  # ['zing', 'ring']

=back

=cut

=head2 ring_specification

  ring_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The ring_specification method returns a I<ring> specification, class name and
args, for the reifier.

=over 4

=item ring_specification example #1

  # given: synopsis

  $app->ring_specification;

  # [['zing', 'ring'], [@args]]

=back

=cut

=head2 ringer

  ringer(Any @args) : Ring

The ringer method returns a new L<Zing::Ringer> object based on the currenrt C<env>.

=over 4

=item ringer example #1

  # given: synopsis

  my $ringer = $app->ringer(
    schemes => [
      ['MyApp1', [], 1],
      ['MyApp2', [], 1],
    ],
  );

  # Zing::Ringer->new(...)

=back

=cut

=head2 ringer_namespace

  ringer_namespace() : ArrayRef[Str]

The ringer_namespace method returns a wordlist that represents a I<ringer>
class name.

=over 4

=item ringer_namespace example #1

  # given: synopsis

  $app->ringer_namespace;

  # ['zing', 'ringer']

=back

=cut

=head2 ringer_specification

  ringer_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The ringer_specification method returns a I<ringer> specification, class name
and args, for the reifier.

=over 4

=item ringer_specification example #1

  # given: synopsis

  $app->ringer_specification;

  # [['zing', 'ringer'], [@args]]

=back

=cut

=head2 savepoint

  savepoint(Any @args) : Savepoint

The savepoint method returns a new L<Zing::Savepoint> object based on the currenrt C<env>.

=over 4

=item savepoint example #1

  # given: synopsis

  my $savepoint = $app->savepoint(
    lookup => $app->lookup(
      name => 'people',
    )
  );

  # Zing::Savepoint->new(...)

=back

=cut

=head2 savepoint_namespace

  savepoint_namespace() : ArrayRef[Str]

The savepoint_namespace method returns a wordlist that represents a
I<savepoint> class name.

=over 4

=item savepoint_namespace example #1

  # given: synopsis

  $app->savepoint_namespace;

  # ['zing', 'savepoint']

=back

=cut

=head2 savepoint_specification

  savepoint_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The savepoint_specification method returns a I<savepoint> specification, class
name and args, for the reifier.

=over 4

=item savepoint_specification example #1

  # given: synopsis

  $app->savepoint_specification;

  # [['zing', 'savepoint'], [@args]]

=back

=cut

=head2 scheduler

  scheduler(Any @args) : Scheduler

The scheduler method returns a new L<Zing::Scheduler> object based on the currenrt C<env>.

=over 4

=item scheduler example #1

  # given: synopsis

  my $scheduler = $app->scheduler;

  # Zing::Scheduler->new(...)

=back

=cut

=head2 scheduler_namespace

  scheduler_namespace() : ArrayRef[Str]

The scheduler_namespace method returns a wordlist that represents a
I<scheduler> class name.

=over 4

=item scheduler_namespace example #1

  # given: synopsis

  $app->scheduler_namespace;

  # ['zing', 'scheduler']

=back

=cut

=head2 scheduler_specification

  scheduler_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The scheduler_specification method returns a I<scheduler> specification, class
name and args, for the reifier.

=over 4

=item scheduler_specification example #1

  # given: synopsis

  $app->scheduler_specification;

  # [['zing', 'scheduler'], [@args]]

=back

=cut

=head2 search

  search(Any @args) : Search

The search method returns a new L<Zing::Search> object based on the currenrt C<env>.

=over 4

=item search example #1

  # given: synopsis

  my $search = $app->search;

  # Zing::Search->new(...)

=back

=cut

=head2 search_namespace

  search_namespace() : ArrayRef[Str]

The search_namespace method returns a wordlist that represents a I<search>
class name.

=over 4

=item search_namespace example #1

  # given: synopsis

  $app->search_namespace;

  # ['zing', 'search']

=back

=cut

=head2 search_specification

  search_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The search_specification method returns a I<search> specification, class name
and args, for the reifier.

=over 4

=item search_specification example #1

  # given: synopsis

  $app->search_specification;

  # [['zing', 'search'], [@args]]

=back

=cut

=head2 simple

  simple(Any @args) : Simple

The simple method returns a new L<Zing::Simple> object based on the currenrt C<env>.

=over 4

=item simple example #1

  # given: synopsis

  my $simple = $app->simple;

  # Zing::Simple->new(...)

=back

=cut

=head2 simple_namespace

  simple_namespace() : ArrayRef[Str]

The simple_namespace method returns a wordlist that represents a I<simple>
class name.

=over 4

=item simple_namespace example #1

  # given: synopsis

  $app->simple_namespace;

  # ['zing', 'simple']

=back

=cut

=head2 simple_specification

  simple_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The simple_specification method returns a I<simple> specification, class name
and args, for the reifier.

=over 4

=item simple_specification example #1

  # given: synopsis

  $app->simple_specification;

  # [['zing', 'simple'], [@args]]

=back

=cut

=head2 single

  single(Any @args) : Single

The single method returns a new L<Zing::Single> object based on the currenrt C<env>.

=over 4

=item single example #1

  # given: synopsis

  my $single = $app->single;

  # Zing::Single->new(...)

=back

=cut

=head2 single_namespace

  single_namespace() : ArrayRef[Str]

The single_namespace method returns a wordlist that represents a I<single>
class name.

=over 4

=item single_namespace example #1

  # given: synopsis

  $app->single_namespace;

  # ['zing', 'single']

=back

=cut

=head2 single_specification

  single_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The single_specification method returns a I<single> specification, class name
and args, for the reifier.

=over 4

=item single_specification example #1

  # given: synopsis

  $app->single_specification;

  # [['zing', 'single'], [@args]]

=back

=cut

=head2 space

  space(Str @args) : Space

The space method returns a new L<Data::Object::Space> object.

=over 4

=item space example #1

  # given: synopsis

  my $space = $app->space(
    'zing',
  );

  # Data::Object::Space->new(...)

=back

=cut

=head2 spawner

  spawner(Any @args) : Spawner

The spawner method returns a new L<Zing::Spawner> object based on the currenrt C<env>.

=over 4

=item spawner example #1

  # given: synopsis

  my $spawner = $app->spawner;

  # Zing::Spawner->new(...)

=back

=cut

=head2 spawner_namespace

  spawner_namespace() : ArrayRef[Str]

The spawner_namespace method returns a wordlist that represents a I<spawner>
class name.

=over 4

=item spawner_namespace example #1

  # given: synopsis

  $app->spawner_namespace;

  # ['zing', 'spawner']

=back

=cut

=head2 spawner_specification

  spawner_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The spawner_specification method returns a I<spawner> specification, class name
and args, for the reifier.

=over 4

=item spawner_specification example #1

  # given: synopsis

  $app->spawner_specification;

  # [['zing', 'spawner'], [@args]]

=back

=cut

=head2 store

  store(Any @args) : Store

The store method returns a new L<Zing::Store> object based on the currenrt C<env>.

=over 4

=item store example #1

  # given: synopsis

  my $store = $app->store;

  # Zing::Store::Hash->new(...)

  # e.g.
  # $app->env->store # Zing::Store::Hash

  # e.g.
  # $ENV{ZING_STORE} # Zing::Store::Hash

=back

=cut

=head2 store_namespace

  store_namespace() : ArrayRef[Str]

The store_namespace method returns a wordlist that represents a I<store> class
name.

=over 4

=item store_namespace example #1

  # given: synopsis

  $app->store_namespace;

  # $ENV{ZING_STORE}

=back

=cut

=head2 store_specification

  store_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The store_specification method returns a I<store> specification, class name and
args, for the reifier.

=over 4

=item store_specification example #1

  # given: synopsis

  $app->store_specification;

  # [['zing', 'store'], [@args]]

=back

=cut

=head2 table

  table(Any @args) : Table

The table method returns a new L<Zing::Table> object based on the currenrt C<env>.

=over 4

=item table example #1

  # given: synopsis

  my $table = $app->table(
    name => 'people',
  );

  # Zing::Table->new(...)

=back

=cut

=head2 table_namespace

  table_namespace() : ArrayRef[Str]

The table_namespace method returns a wordlist that represents a I<table> class
name.

=over 4

=item table_namespace example #1

  # given: synopsis

  $app->table_namespace;

  # ['zing', 'table']

=back

=cut

=head2 table_specification

  table_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The table_specification method returns a I<table> specification, class name and
args, for the reifier.

=over 4

=item table_specification example #1

  # given: synopsis

  $app->table_specification;

  # [['zing', 'table'], [@args]]

=back

=cut

=head2 term

  term(Any @args) : Term

The term method returns a new L<Zing::Term> object based on the currenrt C<env>.

=over 4

=item term example #1

  # given: synopsis

  my $term = $app->term(
    $app->process,
  );

  # Zing::Term->new(...)

=back

=cut

=head2 timer

  timer(Any @args) : Timer

The timer method returns a new L<Zing::Timer> object based on the currenrt C<env>.

=over 4

=item timer example #1

  # given: synopsis

  my $timer = $app->timer;

  # Zing::Timer->new(...)

=back

=cut

=head2 timer_namespace

  timer_namespace() : ArrayRef[Str]

The timer_namespace method returns a wordlist that represents a I<timer> class
name.

=over 4

=item timer_namespace example #1

  # given: synopsis

  $app->timer_namespace;

  # ['zing', 'timer']

=back

=cut

=head2 timer_specification

  timer_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The timer_specification method returns a I<timer> specification, class name and
args, for the reifier.

=over 4

=item timer_specification example #1

  # given: synopsis

  $app->timer_specification;

  # [['zing', 'timer'], [@args]]

=back

=cut

=head2 watcher

  watcher(Any @args) : Watcher

The watcher method returns a new L<Zing::Watcher> object based on the currenrt C<env>.

=over 4

=item watcher example #1

  # given: synopsis

  my $watcher = $app->watcher;

  # Zing::Watcher->new(...)

=back

=cut

=head2 watcher_namespace

  watcher_namespace() : ArrayRef[Str]

The watcher_namespace method returns a wordlist that represents a I<watcher>
class name.

=over 4

=item watcher_namespace example #1

  # given: synopsis

  $app->watcher_namespace;

  # ['zing', 'watcher']

=back

=cut

=head2 watcher_specification

  watcher_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The watcher_specification method returns a I<watcher> specification, class name
and args, for the reifier.

=over 4

=item watcher_specification example #1

  # given: synopsis

  $app->watcher_specification;

  # [['zing', 'watcher'], [@args]]

=back

=cut

=head2 worker

  worker(Any @args) : Worker

The worker method returns a new L<Zing::Worker> object based on the currenrt C<env>.

=over 4

=item worker example #1

  # given: synopsis

  my $worker = $app->worker;

  # Zing::Worker->new(...)

=back

=cut

=head2 worker_namespace

  worker_namespace() : ArrayRef[Str]

The worker_namespace method returns a wordlist that represents a I<worker>
class name.

=over 4

=item worker_namespace example #1

  # given: synopsis

  $app->worker_namespace;

  # ['zing', 'worker']

=back

=cut

=head2 worker_specification

  worker_specification(Any @args) : Tuple[ArrayRef, ArrayRef]

The worker_specification method returns a I<worker> specification, class name
and args, for the reifier.

=over 4

=item worker_specification example #1

  # given: synopsis

  $app->worker_specification;

  # [['zing', 'worker'], [@args]]

=back

=cut

=head2 zang

  zang() : App

The zang method returns a new L<Zing::Zang> object.

=over 4

=item zang example #1

  # given: synopsis

  $app = $app->zang;

  # Zing::App->new(name => 'zing/zang')

=back

=cut

=head2 zing

  zing(Any @args) : Zing

The zing method returns a new L<Zing> object.

=over 4

=item zing example #1

  # given: synopsis

  my $zing = $app->zing(
    scheme => ['MyApp', [], 1],
  );

  # Zing->new(...)

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
