package Thrift::API::HiveClient2;
$Thrift::API::HiveClient2::VERSION = '0.024';
{
  $Thrift::API::HiveClient2::DIST = 'Thrift-API-HiveClient2';
}

# ABSTRACT: Perl to HiveServer2 Thrift API wrapper

use 5.010;
use strict;
use warnings;
use Moo;
use Carp;
use Scalar::Util qw( reftype blessed );
use List::MoreUtils 'zip';

use Thrift;
use Thrift::Socket;
use Thrift::BufferedTransport;

# Protocol loading is done dynamically later.

use Thrift::API::HiveClient2::TCLIService;

# See https://msdn.microsoft.com/en-us/library/ms711683(v=vs.85).aspx
my @odbc_coldesc_fields = qw(
    TABLE_CAT
    TABLE_SCHEM
    TABLE_NAME
    COLUMN_NAME
    DATA_TYPE
    TYPE_NAME
    COLUMN_SIZE
    BUFFER_LENGTH
    DECIMAL_DIGITS
    NUM_PREC_RADIX
    NULLABLE
    REMARKS
    COLUMN_DEF
    SQL_DATA_TYPE
    SQL_DATETIME_SUB
    CHAR_OCTET_LENGTH
    ORDINAL_POSITION
    IS_NULLABLE
);

my @tabledesc_fields = qw(
    TABLE_CAT
    TABLE_SCHEM
    TABLE_NAME
    TABLE_TYPE
    REMARKS
);

# Don't use XS for now, fails initializing properly with BufferedTransport. See
# Thrift::XS documentation.
has use_xs => (
    is      => 'rwp',
    default => sub {0},
    lazy    => 1,
);

has host => (
    is      => 'ro',
    default => sub {'localhost'},
);
has port => (
    is      => 'ro',
    default => sub {10_000},
);
has sasl => (
    is      => 'ro',
    default => 0,
);

# Kerberos principal
# Usually in the format 'hive/{hostname}@REALM.COM';
has principal => (
    is => 'rw',
);

# 1 hour default recv socket timeout. Increase for longer-running queries
# called "timeout" for simplicity's sake, as this is how a user will experience
# it: a time after which the Thrift stack will throw an exception if not
# getting an answer from the server

has timeout => (
    is      => 'rw',
    default => sub {3_600},
);

# These exist to make testing with various other Thrift Implementation classes
# easier, eventually.

has _socket    => ( is => 'rwp', lazy => 1 );
has _transport => ( is => 'rwp', lazy => 1 );
has _protocol  => ( is => 'rwp', lazy => 1 );
has _client    => ( is => 'rwp', lazy => 1 );
has _sasl      => ( is => 'rwp', lazy => 1 );

# setters implied by the 'rwp' mode on the attrs above.

sub _set_socket    { $_[0]->{_socket}    = $_[1] }
sub _set_transport { $_[0]->{_transport} = $_[1] }
sub _set_protocol  { $_[0]->{_protocol}  = $_[1] }
sub _set_client    { $_[0]->{_client}    = $_[1] }

sub _set_sasl {
    my ( $self, $sasl ) = @_;
    return if !$sasl;

    # This normally selects XS first (hopefully)
    require Authen::SASL;
    Authen::SASL->import;

    require Thrift::SASL::Transport;
    Thrift::SASL::Transport->import;

    if ( $sasl == 1 ) {
        return $self->{_sasl} = Authen::SASL->new( mechanism => 'GSSAPI' );
    }
    elsif ( reftype $sasl eq "HASH" ) {
        return $self->{_sasl} = Authen::SASL->new(%$sasl);    #, debug => 8 );
    }
    die "Incorrect parameter passed to _set_sasl";
}

# after constructon is complete, initialize any attributes that
# weren't set in the constructor.
sub BUILD {
    my $self = shift;

    $self->_set_socket( Thrift::Socket->new( $self->host, $self->port ) )
        unless $self->_socket;
    $self->_socket->setRecvTimeout( $self->timeout * 1000 );

    $self->_set_sasl( $self->sasl ) if ( $self->sasl && !$self->_sasl );

    if ( !$self->_transport ) {
        my $transport = Thrift::BufferedTransport->new( $self->_socket );
        if ( $self->_sasl ) {
            my $debug = 0;
            $self->_set_transport( Thrift::SASL::Transport->new( $transport, $self->_sasl, $debug, $self->principal ) );
        }
        else {
            $self->_set_transport($transport);
        }
    }

    $self->_set_protocol( $self->_init_protocol( $self->_transport ) )
        unless $self->_protocol;

    $self->_set_client( Thrift::API::HiveClient2::TCLIServiceClient->new( $self->_protocol ) )
        unless $self->_client;
}

sub _init_protocol {
    my $self = shift;
    my $err;
    my $protocol = eval {
        $self->use_xs
            && require Thrift::XS::BinaryProtocol;
        Thrift::XS::BinaryProtocol->new( $self->_transport );
    } or do { $err = $@; 0 };
    $protocol
        ||= do { require Thrift::BinaryProtocol; Thrift::BinaryProtocol->new( $self->_transport ) };
    $self->_set_use_xs(0) if ref($protocol) !~ /XS/;

    # TODO Add warning when XS was asked but failed to load
    return $protocol;
}

sub connect {
    my ($self) = @_;
    $self->_transport->open;
}

has _session => (
    is  => 'rwp',
    isa => sub {
        my($val) = @_;
        if (   !blessed( $val )
            || !$val->isa('Thrift::API::HiveClient2::TOpenSessionResp')
        ) {
            die sprintf "Session `%s` isn't a Thrift::API::HiveClient2::TOpenSessionResp",
                $val // '[undefined]'
            ;
        }
    },
    lazy    => 1,
    builder => '_build_session',
);

has username => (
    is      => 'rwp',
    lazy    => 1,
    default => sub { $ENV{USER} },
);

has password => (
    is      => 'rwp',
    lazy    => 1,
    default => sub {''},
);

sub _build_session {
    my $self = shift;
    $self->_transport->open if !$self->_transport->isOpen;
    return $self->_client->OpenSession(
        Thrift::API::HiveClient2::TOpenSessionReq->new(
            {   username => $self->username,
                password => $self->password,
            }
        )
    );
}

has _session_handle => (
    is  => 'rwp',
    isa => sub {
        my($val) = @_;
        if (   !blessed( $val )
            || !$val->isa('Thrift::API::HiveClient2::TSessionHandle')
        ) {
            die sprintf "Session handle `%s` isn't a Thrift::API::HiveClient2::TSessionHandle",
                            $val // '[undefined]'
            ;
        }
    },
    lazy    => 1,
    builder => '_build_session_handle',
    predicate => '_has_session_handle',
);

sub _build_session_handle {
    my $self = shift;
    return $self->_session->{sessionHandle};
}

has _operation => (
    is  => "rwp",
    isa => sub {
        my($val) = @_;
        if ( defined $val
            && (
                !blessed( $val )
                || (   !$val->isa('Thrift::API::HiveClient2::TExecuteStatementResp')
                    && !$val->isa('Thrift::API::HiveClient2::TGetColumnsResp')
                    && !$val->isa('Thrift::API::HiveClient2::TGetTablesResp')
                    )
            )
        ) {
            die "Operation `%s` isn't a Thrift::API::HiveClient2::T*Resp",
                    $val // '[undefined]'
            ;
        }
    },
    lazy => 1,
);

has _operation_handle => (
    is  => 'rwp',
    isa => sub {
        my($val) = @_;
        if (
            defined $val
            && (   !blessed( $val )
                || !$val->isa('Thrift::API::HiveClient2::TOperationHandle')
                )
        ) {
            die sprintf "Operation handle isn't a Thrift::API::HiveClient2::TOperationHandle",
                            $val // '[undefined]'
            ;
        }
    },
    lazy => 1,
);

sub _cleanup_previous_operation {
    my $self = shift;

    # We seeem to have some memory leaks in the Hive server, let's try freeing the
    # operation handle explicitely
    if ( $self->_operation_handle ) {
        $self->_client->CloseOperation(
            Thrift::API::HiveClient2::TCloseOperationReq->new(
                { operationHandle => $self->_operation_handle, }
            )
        );
        $self->_set__operation(undef);
        $self->_set__operation_handle(undef);
    }
}

sub execute {
    my $self = shift;
    my ($query) = @_;    # make this a bit more flexible

    $self->_cleanup_previous_operation;

    my $rh = $self->_client->ExecuteStatement(
        Thrift::API::HiveClient2::TExecuteStatementReq->new(
            { sessionHandle => $self->_session_handle, statement => $query, confOverlay => {} }
        )
    );
    if ( $rh->{status}{errorCode} ) {
        die __PACKAGE__ . "::execute: $rh->{status}{errorMessage}; HQL was: \"$query\"";
    }
    $self->_set__operation($rh);
    $self->_set__operation_handle( $rh->{operationHandle} );
    return $rh;
}

{
    # cache the column names we need to extract from the bloated data structure
    # (keyed on query)
    my ( $column_keys, $column_names );

    sub fetch_hashref {
        my $self = shift;
        my ( $rh, $rows_at_a_time ) = @_;
        return $self->fetch( $rh, $rows_at_a_time, 1 );
    }

    sub fetch {
        my $self = shift;
        my ( $rh, $rows_at_a_time, $use_hashref ) = @_;

        # if $rh looks like a number, use it instead of $rows_at_a_time
        # it means we're using the new form for this call, which takes only the
        # number of wanted rows, or even nothing (and relies on the defaults,
        # and a cached copy of the query $rh)
        $rows_at_a_time = $rh if ( $rh && !$rows_at_a_time && $rh =~ /^[1-9][0-9]*$/ );
        $rows_at_a_time ||= 10_000;

        my $result = [];
        my $has_more_rows;

        # NOTE we don't use the provided $rh any more, maybe we should leave
        # that possibility open for parallel queries, but that would need a lot
        # more testing. Patches welcome.
        my $cached_rh = $self->_operation_handle;
        $rh = $self->_client->FetchResults(
            Thrift::API::HiveClient2::TFetchResultsReq->new(
                {   operationHandle => $cached_rh,
                    maxRows         => $rows_at_a_time,
                }
            )
        );
        if ( ref $rh eq 'Thrift::API::HiveClient2::TFetchResultsResp' ) {

            # NOTE that currently (july 2013) the hasMoreRows method is broken,
            # see the explanation in the POD
            $has_more_rows = $rh->hasMoreRows();

            for my $row ( @{ $rh->{results}{rows} || [] } ) {

                # Find which fields to extract from each row, only on the first iteration
                if ( !@{ $column_keys->{$cached_rh} || [] } ) {

                    # metadata for the query
                    if ($use_hashref) {
                        my $rh_meta = $self->_client->GetResultSetMetadata(
                            Thrift::API::HiveClient2::TGetResultSetMetadataReq->new(
                                { operationHandle => $cached_rh }
                            )
                        );
                        $column_names = [ map { $_->{columnName} }
                                @{ $rh_meta->{schema}{columns} || [] } ];
                    }

                    # TODO redo all this using the TGetResultSetMetadataResp object we retrieved
                    # above
                    for my $column ( @{ $row->{colVals} || [] } ) {

                        my $first_col = {%$column};

                        # Only 1 element of each TColumnValue is populated
                        # (although 7 keys are present, 1 for each possible data
                        # type) with a T*Value, and the rest is undef. Find out
                        # which is defined, and put the key (i.e. the data type) in
                        # cache, to reuse it to fetch the next rows faster.
                        # NOTE this data structure smells of Java and friends from
                        # miles away. Dynamically typed languages don't really need
                        # the bloat.
                        push @{ $column_keys->{$cached_rh} },
                            grep { ref $first_col->{$_} } keys %$first_col;
                    }
                }

                # TODO find something faster? (see comment above)

                my $idx    = 0;
                my $retval = [
                    map  { $_->value }
                    grep { defined $_ }
                    map  { $row->{colVals}[ $idx++ ]{$_} } @{ $column_keys->{$cached_rh} }
                ];
                if ($use_hashref) {
                    push @$result, { zip @$column_names, @$retval };
                }
                else {
                    push @$result, $retval;
                }
            }
        }
        return wantarray ? ( $result, $has_more_rows ) : ( @$result ? $result : undef );
    }
}

sub get_columns {
    my $self = shift;
    my ( $table, $schema ) = @_;

    # note that not specifying a table name would return all columns for all
    # tables we probably don't want that, but feel free to change this
    # behaviour. Same goes for the schema name: we probably want a default
    # value for the schema, which is what we use here.
    die "Unspecified table name" if !$table;
    $schema //= "default";

    $self->_cleanup_previous_operation;

    my $rh = $self->_client->GetColumns(
        Thrift::API::HiveClient2::TGetColumnsReq->new(
            {   sessionHandle => $self->_session_handle,
                catalogName   => undef,
                schemaName    => $schema,
                tableName     => $table,
                columnName    => undef,
                confOverlay   => {}
            }
        )
    );
    if ( $rh->{status}{errorCode} ) {
        die __PACKAGE__ . "::execute: $rh->{status}{errorMessage}";
    }
    $self->_set__operation($rh);
    $self->_set__operation_handle( $rh->{operationHandle} );
    my $columns;
    while ( my $res = $self->fetch($rh) ) {
        for my $line (@$res) {
            my $idx = 0;
            push @$columns, { map { $_ => $line->[ $idx++ ] } @odbc_coldesc_fields };
        }
    }
    return $columns;
}

sub get_tables {
    my $self = shift;
    my ( $schema, $table_pattern ) = @_;

    # note that not specifying a table name would return all columns for all
    # tables we probably don't want that, but feel free to change this
    # behaviour. Same goes for the schema name: we probably want a default
    # value for the schema, which is what we use here.
    $schema //= "default";

    $self->_cleanup_previous_operation;

    my $rh = $self->_client->GetTables(
        Thrift::API::HiveClient2::TGetTablesReq->new(
            {   sessionHandle => $self->_session_handle,
                catalogName   => undef,
                schemaName    => $schema,
                tableName     => $table_pattern,
                confOverlay   => {},
            }
        )
    );
    if ( $rh->{status}{errorCode} ) {
        die __PACKAGE__ . "::execute: $rh->{status}{errorMessage}";
    }
    $self->_set__operation($rh);
    $self->_set__operation_handle( $rh->{operationHandle} );
    my $tables;
    while ( my $res = $self->fetch($rh) ) {
        for my $line (@$res) {
            my $idx = 0;
            push @$tables, { map { $_ => $line->[ $idx++ ] } @tabledesc_fields };
        }
    }
    return $tables;
}

sub DEMOLISH {
    my $self = shift;

    $self->_cleanup_previous_operation;

    if ( $self->_has_session_handle ) {
        $self->_client->CloseSession(
            Thrift::API::HiveClient2::TCloseSessionReq->new(
                { sessionHandle => $self->_session_handle, }
            )
        );
    }
    
    if ( $self->_transport ) {
        $self->_transport->close;
    }
}

# when the user calls a method on an object of this class, see if that method
# exists on the TCLIService object. If so, create a sub that calls that method
# on the client object. If not, die horribly.
sub AUTOLOAD {
    my ($self) = @_;
    ( my $meth = our $AUTOLOAD ) =~ s/.*:://;
    return if $meth eq 'DESTROY';
    print STDERR "$meth\n";
    no strict 'refs';
    if ( $self->_client->can($meth) ) {
        *$AUTOLOAD = sub { shift->_client->$meth(@_) };
        goto &$AUTOLOAD;
    }
    croak "No such method exists: $AUTOLOAD";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Thrift::API::HiveClient2 - Perl to HiveServer2 Thrift API wrapper

=head1 VERSION

version 0.024

=for Pod::Coverage BUILD DEMOLISH

=head1 METHODS

=head2 new

Initialize the client object with the Hive server parameters

    my $client = Thrift::API::HiveClient2->new(
        host    => $hive_host,
        port    => $hive_port,
        timeout => $seconds,
    );

=head3 host

Host name or IP, defaults to localhost.

=head3 port

Hive port, defaults to 10000.

=head3 principal

Kerberos principal. Default is not set. See the L</WARNING> section.

=head3 sasl

Enables authentication. Default is not set. See the L</WARNING> section.

=head3 timeout

Seconds timeout, defaults to 1 hour.

=head2 connect

Open the connection on the server declared in the object's constructor.

     $client->connect() or die "Failed to connect";

=head2 execute

Run an HiveQl statement on an open connection.

    my $rh = $client->execute( <HiveQL statement> );

=head2 fetch

Returns an array(ref) of arrayrefs, like DBI's fetchall_arrayref, and a boolean
indicator telling wether or not a subsequent call to fetch() will return more
rows.

    my ($rv, $has_more_rows) = $client->fetch( $rh, <maximum records to retrieve> );

IMPORTANT: The version of HiveServer2 that we use for testing is the one
bundled with CDH 4.2.1. The hasMoreRows method is currently broken, and always
returns false. So the right way of obtaining the resultset is to keep using
fetch() until it returns an empty array. For this reason the behaviour of fetch
has been altered in scalar context (which becomes the current advised way of
retrieving the data):

    # $rv will be an arrayref is anything was fetched, and undef otherwise.
    #
    while (my $rv = $client->fetch( $rh, <maximum records to retrieve> )) {
        # ... do something with @$rv
    }

This is the approach adopted in
L<https://github.com/cloudera/hue/blob/master/apps/beeswax/src/beeswax/server/hive_server2_lib.py>

Starting with version 0.12, we cache the operation handle and don't need it as
a first parameter for the fetch() call. We want to be backward-compatible
though, so depending on the type of the first parameter, we'll ignore it (since
we cached it in the object and we can get it from there) or we'll use it as the
number of rows to be retrieved if it looks like a positive integer:

     my $rv = $client->fetch( 10_000 );

=head2 fetch_hashref

Same use as above, but result is returned as an arrayref of hashes (which keys are
the column names)

=head2 get_columns

Get the columns description for a table, returned in an array of hashrefs which keys are named after the result of an
ODBC GetColumns call. "default" is used for the schema name is none is specified as 2nd argument. The hashes keys
documentation can be found on https://msdn.microsoft.com/en-us/library/ms711683(v=vs.85).aspx for instance.

    my $columns = $client->get_columns('<table name>'[, '<schema name>']);

=head2 get_tables

Get a list of tables. Optional table name pattern as a first argument (use undef or '%' to get all tables while
defining a schema as a second argument), and optional schema second arg (default is "default")

    my $tables = $client->get_tables(['<table pattern, SQL wildcards accepted>', ['<schema name>']]);

Returns an arrayref of hashes:

    [...
    {
        'REMARKS' => 'test comment', # table comment
        'TABLE_NAME' => 'foo_bar',   # table name
        'TABLE_SCHEM' => 'default',  # schema ("database")
        'TABLE_TYPE' => 'TABLE',     # TABLE, VIEW, etc
        'TABLE_CAT' => '',           # catalog (unused?)
    }];

=head1 WARNING

Thrift in Perl originally did not support SASL, so authentication needed to be
disabled on HiveServer2 by setting this property in your
/etc/hive/conf/hive-site.xml. Although the property is documented, this *value*
-which disables the SASL server transport- is not, AFAICT.

    <property>
      <name>hive.server2.authentication</name>
      <value>NOSASL</value>
    </property>

Starting with 0.014, support for secure clusters has been added thanks to
L<Thrift::SASL::Transport>. This behaviour is set by passing sasl => 1 to the
constructor. It has been tested with hive.server2.authentication = KERBEROS.
It of course requires a valid credentials cache (kinit) or keytab.
With this, kerberos principal also should be provided as part of constructor,
principal => hive/_HOST@REALM.COM
this value will be under hive.server2.authentication.kerberos.principal in hive-site.xml

Starting with 0.015, other authentication methods are supported, and driven by
the content of the sasl property. When built using sasl => 0 or sasl => 1, the
behaviour is unchanged. When passed a hashref of arguments that follow the
L<Authen::SASL> syntax for object creation, it is passed directly to
Authen::SASL, for instance:

    {
      mechanism  => 'PLAIN',
      callback   => {
        canonuser => $USER, # not 'user', as I thought reading Authen::SASL's doc
        password  => "foobar",
      }
    }

Note that a server configured with NONE will happily accept the PLAIN method.

=head1 DELEGATIONTOKEN
Sasl object need to be created specifically if hiveClient2 is used with delegation token.
    {
      mechanism  => 'DIGEST-MD5',
      callback   => {
        canonuser => <bas65 encoded identifier extracted from delegation token>,
        password  => <bas65 encoded password extracted from delegation token>,
        realm     => 'default'
      }
    }
This is used when hiveclient is called from oozie, where keytabs cannot be used.
Oozie requests delegationtoken on behalf of hive if specified. This token is used for
further authentication purposes.

=head1 CAVEATS

The instance of hiveserver2 we have didn't return results encoded in UTF8, for
the reason mentioned here:
L<https://groups.google.com/a/cloudera.org/d/msg/cdh-user/AXeEuaFP0Ro/Txmn1OHleAsJ>

So we had to change the init script for hive-server2 to make it behave, adding
'-Dfile.encoding=UTF-8' to HADOOP_OPTS

=head1 REPOSITORY

L<https://github.com/dmorel/Thrift-API-HiveClient2>

=head1 CONTRIBUTORS

Burak Gürsoy (BURAK)

Neil Bowers (NEILB)

=head1 AUTHOR

David Morel <david.morel@amakuru.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Morel & Booking.com. Portions are (c) R.Scaffidi, Thrift files are (c) Apache Software Foundation.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
