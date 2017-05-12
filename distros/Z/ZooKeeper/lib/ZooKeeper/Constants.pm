package ZooKeeper::Constants;
use strict; use warnings;
use ZooKeeper::XS;
use parent 'Exporter';

=head1 NAME

ZooKeeper::Constants

=head1 DESCRIPTION

A class for importing the ZooKeeper C library's enums. Also contains the library's zerror function for retriving string representations of error codes.

By default ZooKeeper::Constants imports all enums into a package. Individual enums can also be exported, along with an export tag for classes of enums

=head1 EXPORT TAGS

=head2 :errors

Error codes returned by the ZooKeeper C library. Includes the zerror function for returning a string corresponding to the error code.

    zerror

    ZOK
    ZSYSTEMERROR
    ZRUNTIMEINCONSISTENCY
    ZDATAINCONSISTENCY
    ZCONNECTIONLOSS
    ZMARSHALLINGERROR
    ZUNIMPLEMENTED
    ZOPERATIONTIMEOUT
    ZBADARGUMENTS
    ZINVALIDSTATE
    ZAPIERROR
    ZNONODE
    ZNOAUTH
    ZBADVERSION
    ZNOCHILDRENFOREPHEMERALS
    ZNODEEXISTS
    ZNOTEMPTY
    ZSESSIONEXPIRED
    ZINVALIDCALLBACK
    ZINVALIDACL
    ZAUTHFAILED
    ZCLOSING
    ZNOTHING

=head2 :node_flags

Flags that may be used during node creation.

    ZOO_EPHEMERAL
    ZOO_SEQUENCE

=head2 :acl_ids

    ZOO_ANYONE_ID_UNSAFE
    ZOO_AUTH_IDS

=head2 :acl_perms

ACL permissions that may be used for a nodes ACLs

    zperm

    ZOO_PERM_READ
    ZOO_PERM_WRITE
    ZOO_PERM_CREATE
    ZOO_PERM_DELETE
    ZOO_PERM_ADMIN
    ZOO_PERM_ALL

=head2 :acls

A predefined set of ACLs.

ACLs can also be constructed manually, as an arrayref of hashrefs, where hashrefs include keys for id, scheme, and perms.

    ZOO_OPEN_ACL_UNSAFE
    ZOO_READ_ACL_UNSAFE
    ZOO_CREATOR_ALL_ACL

=head2 :events

Possible ZooKeeper event types. These are used for the type key of the event hashref, passed to ZooKeeper watcher callbacks.

    zevent

    ZOO_CREATED_EVENT
    ZOO_DELETED_EVENT
    ZOO_CHANGED_EVENT
    ZOO_CHILD_EVENT
    ZOO_SESSION_EVENT
    ZOO_NOTWATCHING_EVENT

=head2 :states

Possible ZooKeeper connection states. These are used for the state key of the event hashref, passed to ZooKeeper watcher callbacks.

    zstate

    ZOO_EXPIRED_SESSION_STATE
    ZOO_AUTH_FAILED_STATE
    ZOO_CONNECTING_STATE
    ZOO_ASSOCIATING_STATE
    ZOO_CONNECTED_STATE

=cut

our %EXPORT_TAGS = (
    'errors' => [qw(
        ZOK
        ZSYSTEMERROR
        ZRUNTIMEINCONSISTENCY
        ZDATAINCONSISTENCY
        ZCONNECTIONLOSS
        ZMARSHALLINGERROR
        ZUNIMPLEMENTED
        ZOPERATIONTIMEOUT
        ZBADARGUMENTS
        ZINVALIDSTATE
        ZAPIERROR
        ZNONODE
        ZNOAUTH
        ZBADVERSION
        ZNOCHILDRENFOREPHEMERALS
        ZNODEEXISTS
        ZNOTEMPTY
        ZSESSIONEXPIRED
        ZINVALIDCALLBACK
        ZINVALIDACL
        ZAUTHFAILED
        ZCLOSING
        ZNOTHING
        zerror
    )],
    'node_flags' => [qw(
        ZOO_EPHEMERAL
        ZOO_SEQUENCE
    )],
    'acl_ids' => [qw(
        ZOO_ANYONE_ID_UNSAFE
        ZOO_AUTH_IDS
    )],
    'acl_perms' => [qw(
        ZOO_PERM_READ
        ZOO_PERM_WRITE
        ZOO_PERM_CREATE
        ZOO_PERM_DELETE
        ZOO_PERM_ADMIN
        ZOO_PERM_ALL
        zperm
    )],
    'acls' => [qw(
        ZOO_OPEN_ACL_UNSAFE
        ZOO_READ_ACL_UNSAFE
        ZOO_CREATOR_ALL_ACL
    )],
    'events' => [qw(
        ZOO_CREATED_EVENT
        ZOO_DELETED_EVENT
        ZOO_CHANGED_EVENT
        ZOO_CHILD_EVENT
        ZOO_SESSION_EVENT
        ZOO_NOTWATCHING_EVENT
        zevent
    )],
    'states' => [qw(
        ZOO_EXPIRED_SESSION_STATE
        ZOO_AUTH_FAILED_STATE
        ZOO_CONNECTING_STATE
        ZOO_ASSOCIATING_STATE
        ZOO_CONNECTED_STATE
        zstate
    )],
    'ops' => [qw(
        ZOO_CREATE_OP
        ZOO_DELETE_OP
        ZOO_SETDATA_OP
        ZOO_CHECK_OP
    )],
    'version' => [qw(
        ZOOKEEPER_VERSION
    )],
);

our @EXPORT       = map {@{$EXPORT_TAGS{$_}}} keys %EXPORT_TAGS;
our @EXPORT_OK    = @EXPORT;
$EXPORT_TAGS{all} = \@EXPORT;

use constant ZOO_ANYONE_ID_UNSAFE => (
    id     => 'anyone',
    scheme => 'world',
);

use constant ZOO_AUTH_IDS => (
    id     => '',
    scheme => 'auth',
);

=head1 FUNCTIONS

=head2 zerror

The ZooKeeper C API's zerror. Returns a string corresponding the error code.

=cut

our %_DESCRIPTIONS;
sub _get_descriptions {
    our %_DESCRIPTIONS;
    my ($type, %args) = @_;
    $args{regex} //= qr/ZOO_(.*)_\w+/;
    return $_DESCRIPTIONS{$type} ||= do {
        my @names = grep /^ZOO_/, @{$EXPORT_TAGS{$type}};
        my %descs = map {
            my $enum = __PACKAGE__->can($_)->();
            my ($type) = /$args{regex}/;
            $type =~ tr/_/ /;
            $type =~ s/^NOT(?<!HING)/NOT /;
            ($enum => lc $type)
        } @names;
        \%descs;
    };
}

=head2 zperm

Returns a string corresponding to the acl permission.

=cut

sub zperm {
    my ($enum) = @_;
    my @matches;
    my $perms = _get_descriptions("acl_perms", regex => qr/ZOO_PERM_(.*)/);
    return $perms->{$enum} if $perms->{$enum};

    for my $perm (sort {$perms->{$a} cmp $perms->{$b}} keys %$perms) {
        my $name = $perms->{$perm};
        next if $name eq "all";
        push @matches, $perms->{$perm} if $enum & $perm;
    }
    return join("|", @matches) || "unknown perm";
}

=head2 zevent

Returns a string corresponding to the event type.

=cut

sub zevent {
    my ($enum) = @_;
    my $events = _get_descriptions("events");
    return $events->{$enum} || "unknown event";
}

=head2 zstate

Returns a string corresponding to the connection state.

=cut

sub zstate {
    my ($enum) = @_;
    my $states = _get_descriptions("states");
    return $states->{$enum} || "unknown state";
}


1;
