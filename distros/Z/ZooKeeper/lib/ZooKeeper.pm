package ZooKeeper;
use ZooKeeper::XS;
use ZooKeeper::Constants;
use ZooKeeper::Transaction;
use Carp qw(croak);
use Module::Runtime qw(require_module);
use Moo;
use namespace::autoclean;
use 5.10.1;

our $VERSION = '0.1.10';

BEGIN {
    if (my $trace_var = $ENV{PERL_ZOOKEEPER_TRACE}) {
        my ($level, $file) = split /=/, $trace_var;
        __PACKAGE__->trace($level, ($file)x!! $file);
    }
}

=head1 NAME

ZooKeeper - Perl bindings for Apache ZooKeeper

=head1 SYNOPSIS

    my $zk = ZooKeeper->new(hosts => 'localhost:2181');

    my $cv = AE::cv;
    my @children = $zk->get_children('/', watcher => sub { my $event = shift; $cv->send($event) });
    my $child_event = $cv->recv;

=head1 STATUS

Unstable.

Until version 1.0.0, some aspects of the API may change, most likely related to exception handling for commands and watchers.

=head1 DESCRIPTION

ZooKeeper is a perl interface to the Apache ZooKeeper C client library.

=head2 How is this different from Net::ZooKeeper?

=over 4

=item ZooKeeper is written for asynchronous programming.

To support asynchronous programs, watchers were implemented as code refs, which a ZooKeeper::Dispatcher asynchronously invokes with ZooKeeper event data. Conversely, Net::ZooKeeper used Net::ZooKeeper::Watch classes, which users must interact with using the wait method(which blocks).

=item ZooKeeper data is represented as normal perl data types.

ZooKeeper event and stat data are simply hashrefs and arrayrefs. Net::ZooKeeper instead provides specific perl classes for interacting with this data.

=item ZooKeeper leverages perl exception handling.

Instead of returning the C error codes, as Net::ZooKeeper does, ZooKeeper throws ZooKeeper::Error exceptions for unexpected return codes.

=back

=head2 Data Types

=over 4

=item acl

Acls are represented as an arrayrefs of hashrefs, where each hashref includes an id, scheme, and permissions. Permissions flags can be imported from the ZooKeeper::Constants package.

For instance, ZOO_READ_ACL_UNSAFE would be represented as:

    [{id => 'anyone', scheme => 'world', perms => ZOO_PERM_READ}]

=item event

A hashref of attributes for a watcher event. Includes the type of event(a ZooKeeper::Constants event), connection state(a ZooKeeper::Constants state) and the path of the node triggering the event.

    {
        path  => '/child',
        state => ZOO_CONNECTED_STATE,
        type  => ZOO_CHILD_EVENT,
    }

=item stat

A hashref of fields from a C Stat struct.

    {
        aversion       => 0,
        ctime          => 0,
        cversion       => 0,
        czxid          => 0,
        ephemeralOwner => 0,
        dataLength     => 0,
        mtime          => 0,
        mzxid          => 0,
        numChildren    => 2,
        pzxid          => 2334,
        version        => 0,
    }

=back

=head2 Dispatchers

ZooKeeper uses ZooKeeper::Dispatchers for communicating with callbacks registered by the C library. These callbacks are executed in separate POSIX threads, which write event data to a ZooKeeper::Channel and notify the dispatcher that an event is ready to be processed. How this notification occurs, and how perl callbacks are invoked, is what differentiates the types of dispatchers.

=over 4

=item AnyEvent

ZooKeeper writes to a Unix pipe with an attached AnyEvent I/O watcher. This means that perl callbacks for watchers will be executed by the AnyEvent event loop.

=item Interrupt

ZooKeeper uses Async::Interrupt callbacks. This means the perl interpreter will be safely interrupted(waits for the current op to finish) in order to execute the corresponding perl callback. See Async::Interrupt for more details on how callbacks are executed. Be aware that this does not interrupt system calls(such as select) and XS code. This means if your code is blocking on a select(such as during an AnyEvent recv), the interrupt callback will not execute until the call has finished.

=item IOAsync

ZooKeeper writes to a Unix pipe with an attached IO::Async::Handle.

The IO::Async dispatcher requires an IO::Async::Loop, and needs to be constructed manually

    my $loop = IO::Async::Loop->new;
    my $disp = ZooKeeper::Dispatcher::IOAsync->new(loop => $loop);
    my $zk = ZooKeeper->new(
        hosts      => 'localhost:2181',
        dispatcher => $disp,
    );

=item Mojo

ZooKeeper writes to a Unix pipe with an attached Mojo::Reactor watcher.

=item POE

ZooKeeper writes to a Unix pipe with an attached POE::Session.

=back

=head1 ATTRIBUTES

=head2 hosts

A comma separated list of ZooKeeper server hostnames and ports.

    'localhost:2181'
    'zoo1.domain:2181,zoo2.domain:2181'

=cut

has hosts => (
    is       => 'ro',
    required => 1,
);

=head2 timeout

The session timout used for the ZooKeeper connection.

=cut

has timeout => (
    is      => 'ro',
    default => 10 * 10**3,
);

=head2 watcher

A subroutine reference to be called by the default watcher for ZooKeeper session events. This attribute is read/write.

=cut

has watcher => (
    is => 'rw',
);

after watcher => sub {
    # this probably makes more sense as a trigger
    #  but triggers get run before BUILD
    #  which is a problem for watch instantiation
    return if @_ == 1;
    my ($self, $code) = @_;
    my ($path, $type) = ('', 'default');
    my %watcher_args  = (path => $path, type => $type);

    my @old = $self->get_watchers(%watcher_args);
    my $new = $self->create_watcher($path => $code, type => $type);
    $self->_set_watcher($new);
    $self->remove_watcher($_) for @old;
};


=head2 authentication

An arrayref used for authenticating with ZooKeeper. This will be passed as an array to add_auth.

    [$scheme, $credentials, %extra]

=cut

has authentication => (
    is => 'ro',
);

=head2 buffer_length

The default length of the buffer used for retrieving ZooKeeper data and paths. Defaults to 2048 bytes.

=cut

has buffer_length => (
    is      => 'ro',
    default => 2048,
);

=head2 client_id

The client_id for a ZooKeeper session. Can be set during construction to resume a previous session.

=cut

=head2 default_acl

=cut

has default_acl => (
    is      => 'ro',
    default => sub { ZOO_OPEN_ACL_UNSAFE },
);

=head2 dispatcher

The implementation of ZooKeeper::Dispatcher to be used. Defaults to AnyEvent.

Valid types include:

=over 4

=item AnyEvent

=item Interrupt

=item Mojo

=item POE

=back

Instead of a string, a dispatcher object can be passed directly. This is necessary if the dispatcher has required attributes(as is the case for ZooKeeper::Dispatcher::IOAsync).

=cut

has dispatcher => (
    is      => 'ro',
    isa     => sub { shift->isa('ZooKeeper::Dispatcher') },
    coerce  => \&_to_dispatcher,
    default => sub { $ENV{PERL_ZOOKEEPER_DISPATCHER} || 'AnyEvent' },
    handles => [qw(
        create_watcher
        get_watchers
        ignore_session_events
        remove_watcher
        wait
    )],
);
sub _to_dispatcher {
    my ($disp) = @_;
    return $disp unless $disp and not ref $disp;

    my $class = $disp =~ s/\^+// ? $disp : "ZooKeeper::Dispatcher::$disp";
    require_module($class);
    return $class->new;
}

=head2 ignore_session_events

If set to false, all watchers will be triggered for session events, such as disconnecting and reconnecting to the ZooKeeper server. This means that watchers can be triggered multiple times, until the watcher event is triggered.

The default value is true, which will only trigger watchers once, for the watcher event.

=cut

sub BUILD {
    my ($self, $args) = @_;

    $self->ignore_session_events($args->{ignore_session_events})
        if exists $args->{ignore_session_events};
    my $watcher = $self->watcher && do {
        $self->create_watcher('' => $self->watcher, type => 'default');
    };

    $self->_xs_init;
    $self->connect(
        authentication => $self->authentication,
        client_id      => $args->{client_id},
        hosts          => $self->hosts,
        timeout        => $self->timeout,
        watcher        => $watcher,
    );
}

sub DEMOLISH {
    my ($self) = @_;
    $self->_xs_destroy;
}

=head1 METHODS

=head2 new

Instantiate a new ZooKeeper connection.

    my $zk = ZooKeeper->new(%args)

        %args
            REQUIRED hosts
            OPTIONAL authentication
            OPTIONAL buffer_length
            OPTIONAL dispatcher
            OPTIONAL timeout
            OPTIONAL watcher

=head2 state

Get the state of the ZooKeeper connection. Returns a state enum from ZooKeeper::Constants.

=head2 wait

Calls wait on the underlying ZooKeeper::Dispatcher.

Synchronously dispatch one event. Returns the event hashref the watcher was called with.
Can optionally be passed a timeout(specified in seconds), which will cause wait to return undef if it does not complete in the specified time.

    my $event = $zk->wait($seconds)

    OPTIONAL $seconds

=cut

around connect => sub {
    my ($orig, $self, %args) = @_;
    my ($hosts, $timeout, $watcher, $client_id, $authentication) =
        @args{qw(hosts timeout watcher client_id authentication)};
    $self->$orig($hosts, $timeout, $watcher, $client_id);
    $self->add_auth(@$authentication) if $authentication;
};

=head2 close

Close a ZooKeeper session.

If the handle was not created by the current process, a ZOO_CLOSE_OP will NOT be sent to the server. Instead, only the underlying socket will be closed.

=head2 reopen

Reopen a ZooKeeper session after forking.

This creates a new ZooKeeper session, without closing the parent session.

=cut

sub reopen {
    my ($self, %args) = @_;
    $self->close;
    # since this creates a new session, don't pass a client_id
    $self->connect(
        authentication => $self->authentication,
        hosts          => $self->hosts,
        timeout        => $self->timeout,
        watcher        => $self->watcher,
        %args,
    );
}

=head2 create

Create a new node with the given path and data. Returns the path for the newly created node on succes. Otherwise a ZooKeeper::Error is thrown.

    my $created_path = $zk->create($requested_path, %extra);

        REQUIRED $requested_path

        OPTIONAL %extra
            acl
            buffer_length
            ephemeral
            sequential
            value

=cut

around create => sub {
    my ($orig, $self, $path, %extra) = @_;
    my $acl   = $extra{acl} // $self->default_acl;
    my $flags = 0;
    $flags |= ZOO_EPHEMERAL if $extra{ephemeral};
    $flags |= ZOO_SEQUENCE  if $extra{sequential};

    no warnings 'uninitialized';
    return $self->$orig(
        $path,
        $extra{value},
        $extra{buffer_length} // $self->buffer_length,
        $acl,
        $flags,
    );
};

=head2 add_auth

Add authentication credentials for the session. Will automatically be invoked if the authentication attribute was set during construction.

A ZooKeeper::Error will be thrown if the request could not be made. To determine success or failure authenticating, a watcher must be passed.

    $zk->add_auth($scheme, $credentials, %extra)

        REQUIRED $scheme
        REQUIRED $credentials

        OPTIONAL %extra
            watcher

=cut

around add_auth => sub {
    my ($orig, $self, $scheme, $credentials, %extra) = @_;
    my $watcher = $extra{watcher} ? $self->create_watcher('', $extra{watcher}, type => 'add_auth') : undef;
    return $self->$orig($scheme, $credentials, $watcher);
};

=head2 delete

Delete a node at the given path. Throws a ZooKeeper::Error if the delete was unsuccessful.

    $zk->delete($path, %extra)

        REQUIRED $path

        OPTIONAL %extra
            version

=cut

around delete => sub {
    my ($orig, $self, $path, %extra) = @_;
    return $self->$orig($path, $extra{version}//-1);
};

=head2 ensure_path

=cut

sub ensure_path {
    my ($self, $path, %extra) = @_;
    return if $self->exists($path);

    my ($parent) = $path =~ m#^(.*)/[^/]+$#;
    $self->ensure_path($parent, %extra) if $parent;
    $self->create($path, %extra);
}

=head2 exists

Check whether a node exists at the given path, and optionally set a watcher for when the node is created or deleted.
On success, returns a stat hashref for the node. Otherwise returns undef.

    my $stat = $zk->exists($path, %extra)

        REQUIRED $path

        OPTIONAL %extra
            watcher

=cut

around exists => sub {
    my ($orig, $self, $path, %extra) = @_;
    my $watcher = $extra{watcher} ? $self->create_watcher($path, $extra{watcher}, type => 'exists') : undef;
    return $self->$orig($path, $watcher);
};

=head2 get_children

Get the children stored directly under the given path. Optionally set a watcher for when a child is created or deleted.
Returns an array of child path names.

    my @child_paths = $zk->get_children($path, %extra)

        REQUIRED $path

        OPTIONAL %extra
            watcher

=cut

around get_children => sub {
    my ($orig, $self, $path, %extra) = @_;
    my $watcher = $extra{watcher} ? $self->create_watcher($path, $extra{watcher}, type => 'get_children') : undef;
    return $self->$orig($path, $watcher);
};

=head2 get

Retrieve data stored at the given path. Optionally set a watcher for when the data is changed.
In list context, the data and stat hashref of the node is returned. Otherwise just the data is returned.

    my $data          = $zk->get($path, %extra)
    my ($data, $stat) = $zk->get($path, %extra)

        REQUIRED $path

        OPTIONAL %extra
            watcher
            buffer_length

=cut

around get => sub {
    my ($orig, $self, $path, %extra) = @_;
    my $watcher = $extra{watcher} ? $self->create_watcher($path, $extra{watcher}, type => 'get') : undef;
    return $self->$orig(
        $path,
        $extra{buffer_length} // $self->buffer_length,
        $watcher,
    );
};

=head2 set

Set data at the given path.
On succes, returns a stat hashref of the node. Otherwise a ZooKeeper::Error is thrown.

    my $stat = $zk->set($path => $value, %extra)

        REQUIRED $path
        REQUIRED $value

        OPTIONAL %extra
            version

=cut

around set => sub {
    my ($orig, $self, $path, $value, %extra) = @_;
    no warnings 'uninitialized';
    return $self->$orig($path, $value, $extra{version}//-1);
};

=head2 get_acl

Get ACLs for the given node.
Returns an ACLs arrayref on success, otherwise throws a ZooKeeper::Error

    my $acl = $zk->get_acl($path)

        REQUIRED $path

=head2 set_acl

Set ACls for a node at the given path. Throws a ZooKeeper::Error on failure.

    $zk->set_acl($path => $acl, %extra)

        REQUIRED $path
        REQUIRED $acl

        OPTIONAL %extra
            version

=cut

around set_acl => sub {
    my ($orig, $self, $path, $acl, %extra) = @_;
    return $self->$orig($path, $acl, $extra{version}//-1);
};

=head2 transaction

Return a ZooKeeper::Transaction for atomically updating multiple nodes.
See L<ZooKeeper::Transaction> for more details on using transactions.

    my $txn = $zk->transaction
                 ->delete( '/some-node'    )
                 ->create( '/another-node' )
    my ($delete_result, $create_result) = $txn->commit;

=cut

sub transaction {
    my ($self) = @_;
    return ZooKeeper::Transaction->new(handle => $self);
}

=head2 trace

Set the tracing level for the ZooKeeper client. Can also be set using the PERL_ZOOKEEPER_TRACE environmental variable, where PERL_ZOOKEEPER_TRACE=$level=$file traces to $file with debug level $level.

    $zk->trace($level, $file)

        REQUIRED $level
        OPTIONAL $file

=cut

=head1 CAVEATS

=head2 Forking

ZooKeeper now offers experimental support for forking safely. A child process may use either the close or reopen methods on a handle, after forking, to destroy the previous connection. Since forking in a multithreaded process is usually very dangerous, this library only closes the underlying socket, and removes references to the previous zhandle.

=head2 Signals

Many ZooKeeper recipes(such as in the examples directory), rely on clients properly shutting down to delete ephemeral nodes. Otherwise the ZooKeeper server will wait for the entire duration of the timeout specified by the session, before cleaning up. If you are expecting your program to handle signals(such as SIGINT), make sure the program is properly catching them and exiting. See the examples for more information.

=head1 SEE ALSO

The Apache ZooKeeper project's home page at
L<http://zookeeper.apache.org/> provides a wealth of detail
on how to develop applications using ZooKeeper.

=head1 AUTHOR

Mark Flickinger <maf@cpan.org>

=head1 LICENSE

This software is licensed under the same terms as Perl itself.

=cut

1;
