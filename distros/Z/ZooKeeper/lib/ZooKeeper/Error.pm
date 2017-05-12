package ZooKeeper::Error;
use Moo;
with 'Throwable';

use overload
    '0+'     => \&numify,
    '""'     => \&stringify,
    fallback => 1;

=head1 NAME

ZooKeeper::Error

=head1 DESCRIPTION

A Throwable class for ZooKeeper exceptions.

=head1 SYNOPSIS

    ZooKeeper::Error->throw({
        code    => ZNONODE,
        error   => 'no node',
        message => "Tried to delete a node that does not exist",
    })

=head1 ATTRIBUTES

=head2 code

The error code returned by the ZooKeeper C library. See ZooKeeper::Constants for possible error codes. This is returned when ZooKeeper::Error's are numified.

=cut

has code => (
    is       => 'ro',
    required => 1,
);

=head2 error

The string corresponding to the ZooKeeper error code, usually given by ZooKeeper::Constant::zerror($code)

=cut

has error => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        require ZooKeeper::Constants;
        ZooKeeper::Constants::zerror($self->code)
    },
);

=head2 message

A descriptive error message for the exception. This is returned when ZooKeeper::Error's are stringified.

=cut

has message => (
    is      => 'ro',
    lazy    => 1,
    default => sub { shift->error },
);

sub numify    { shift->code    }

sub stringify { shift->message }

1;
