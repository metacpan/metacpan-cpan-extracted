package ZooKeeper::Channel;
use ZooKeeper::XS;
use Moo;
use namespace::autoclean;

=head1 NAME

ZooKeeper::Channel


=head1 DESCRIPTION

A perl interface to the C queue used for sending data between ZooKeeper C library and perl.

This class should NOT be used directly. Reading and writing to the channel should be handled via a ZooKeeper::Dispatcher, because only dispatchers know know to handle C structs passed from the ZooKeeper C library. Undocumented methods are primarily intended to be used by unit tests, for testing the underlying C queue implementation.

=head1 METHODS

=head2 size

The current size of the channel. Indicates the number of pending events, waiting to be dispatched.

=cut

sub BUILD { shift->_xs_init }

1;
