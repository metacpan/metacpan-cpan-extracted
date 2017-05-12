package Voldemort::Store;

use Moose;

use Voldemort::ProtoBuff::Connection;

=pod

=head1 NAME

Voldemort::Store

=cut

=head1 DESCRIPTION

The primary interface for interacting with a Voldemort store, synchronously or asynchromously.

=cut

=head1 PROPERTIES

=head2 connection

Moose Voldemort::Connection property, required on instanciation.

=cut

has 'connection' => (
    is       => 'rw',
    isa      => 'Voldemort::Connection',
    required => 1,
);

=head2 connection

Moose string property of the default store to use.  If one is not provided, it must be provided on operations which manipulate data.

=cut

has 'default_store' => (
    is  => 'rw',
    isa => 'Str'
);

=head2 sync

Moose boolean property if the connection should be used synchronously or asynchronously.  Changing this property mid-stride can cause confusion later getting results of operations.

=cut

has 'sync' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1
);

has '_queue' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] }
);

sub _connect {
    my $self = shift;
    if ( !$self->connection()->is_connected() ) {
        $self->connection()->connect();
        $self->connection()->is_connected(1);
    }
    return;
}

sub _handle_response {
    my $self   = shift;
    my $writer = shift;

    $self->connection()->flush();
    return $writer->read( $self->connection() ) if ( $self->sync() );
    unshift( @{ $self->_queue() }, $writer );
    return;
}

=head2 ready

Method which performs a check on the IO::Connection for data.  Defaults to a 1 second wait if the number of seconds is not passed in. 

=cut

sub ready {
    my $self = shift;
    my $wait = shift || 1;
    return $self->connection()->can_read($wait);
}

=head2 next_response

Method that retrieves the next response off the wire.  In synchronous mode, this method is called for you.  In asynchronous mode, you must call this yourself.

=cut

sub next_response {
    my $self       = shift;
    my $op         = pop( @{ $self->_queue() } );
    my $connection = $self->connection();

    return $op->read($connection);
}

=head2 get/put/delete

Methods that perform operations on the store, named for their function.  The first param of the method is a hash of the parameters.  In asynchronous mode, these methods will not deserialize a result off the wire but instead queue them to be read by next_response.

=head3 store

The name of the store in voldemort to manipulate, defaults to default_store. 

=head3 key

Key in which to operate.

=head3 node

For writes and deletes, which vectors are being modified.  In scalar form or array ref, it is considered one writer.  Passing in an array ref of [1,2] will create a single node vector of [1,2].  Then writing with a node of 1 will not modify the vector of [1,2].

=head3 value

Key for puts, the value to store.

=cut

sub delete {
    my ( $self, %params ) = @_;
    my $store = $params{'store'} || $self->default_store();

    $self->_connect();

    if ( $self->connection()->can_write(30) ) {
        my $writer = $self->connection()->delete_handler();

        $writer->write( $self->connection(), $store, $params{'key'},
            $params{'node'} );
        return $self->_handle_response($writer);
    }
    return;
}

sub get {
    my ( $self, %params ) = @_;
    my $store = $params{'store'} || $self->default_store();

    $self->_connect();

    if ( $self->connection()->can_write(30) ) {
        my $writer = $self->connection()->get_handler();
 
        $writer->write( $self->connection(), $store, $params{'key'} );
        return $self->_handle_response($writer);
    }
    return;
}

sub put {
    my ( $self, %params ) = @_;
    my $store = $params{'store'} || $self->default_store();

    $self->_connect();

    if ( $self->connection()->can_write(30) ) {
        my $writer = $self->connection()->put_handler();

        $writer->write( $self->connection(), $store, $params{'key'},
            $params{'value'}, $params{'node'} );

        return $self->_handle_response($writer);
    }
    return;
}

__PACKAGE__->meta->make_immutable;
1;
