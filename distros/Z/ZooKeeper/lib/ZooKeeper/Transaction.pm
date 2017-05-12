package ZooKeeper::Transaction;
use ZooKeeper::XS;
use ZooKeeper::Constants;
use Moo;

=head1 NAME

ZooKeeper::Transaction

=head1 SYNOPSIS

    my $txn = $zk->transaction
                 ->delete( '/some-node'    )
                 ->create( '/another-node' )
    my ($delete_result, $create_result) = $txn->commit;

=head1 DESCRIPTION

A ZooKeeper::Transaction is used for constructing a set of
multiple operations, which must be committed atomically.

=head1 ERRORS

When any of the operations fail, all ops in the transaction
will return hash refs with 'type' set to 'error', and
with 'code' set to the error code for the operation.

=head1 METHODS

=head2 commit

Commit a transaction. Returns a list of op results.

=head2 create

    $txn->create($path, %extra)

        REQUIRED $path

        OPTIONAL %extra
            acl
            buffer_length
            ephemeral
            sequential
            value

Return a tranaction with a create op code.

On commit this will return a hash ref with type 'create',
and with 'path' set to the path to the new node.

=head2 delete

    $txn->delete($path, %extra)

        REQUIRED $path

        OPTIONAL %extra
            version

Return a tranaction with a delete op code.

On commit this will return a hash ref with type 'delete'.

=head2 set

    $txn->set($path, $value, %extra)

        REQUIRED $path
        REQUIRED $value

        OPTIONAL %extra
            version

Return a tranaction with a set op code.

On commit this will return a hash ref with type 'set',
and with 'stat' set a stat hash ref of the updated node.

=head2 check

    $txn->check($path, $version)

        REQUIRED $path
        REQUIRED $version

Return a tranaction with a check op code.

On commit this will return a hash ref with type 'check'.

=cut

has handle => (
    is       => 'ro',
    weak_ref => 1,
    required => 1,
);

has ops => (
    is      => 'ro',
    default => sub { [] },
);

sub _add_op {
    my ($self, $type, @args) = @_;
    return ref($self)->new(
        handle => $self->handle,
        ops    => [
            @{$self->ops},
            [$type, @args],
        ],
    );
}

sub create {
    my ($self, $path, %extra) = @_;
    my ($value, $buffer_length, $acl) = @extra{qw(value buffer_length acl)};
    $buffer_length //= $self->handle->buffer_length;
    $acl           //= ZOO_OPEN_ACL_UNSAFE;
    
    my $flags = 0;
    $flags |= ZOO_EPHEMERAL if $extra{ephemeral};
    $flags |= ZOO_SEQUENCE  if $extra{sequential};

    return $self->_add_op(ZOO_CREATE_OP, $path, $value, $buffer_length, $acl, $flags);
}

sub delete {
    my ($self, $path, %extra) = @_;
    my $version = $extra{version} // -1;
    return $self->_add_op(ZOO_DELETE_OP, $path, $version);
}

sub set {
    my ($self, $path, $value, %extra) = @_;
    my $version = $extra{version} // -1;
    return $self->_add_op(ZOO_SETDATA_OP, $path, $value, $version);
}

sub check {
    my ($self, $path, $version) = @_;
    return $self->_add_op(ZOO_CHECK_OP, $path, $version // -1);
}

around commit => sub {
    my ($orig, $self) = @_;
    my $ops   = $self->ops;
    my $count = @$ops;
    return $self->$orig($self->handle, $count, $ops);
};

1;
