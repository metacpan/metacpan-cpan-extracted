package ZMQ::Raw::Message;
$ZMQ::Raw::Message::VERSION = '0.22';
use strict;
use warnings;
use Carp;
use ZMQ::Raw;

sub AUTOLOAD
{
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&ZMQ::Raw::Message::_constant not defined" if ($constname eq '_o_constant' || $constname eq '_p_constant');
    my ($error, $val) = _o_constant ($constname);
    if ($error)
	{
		($error, $val) = _p_constant ($constname);
		if ($error)
		{
			croak $error;
		}
	}
    {
        no strict 'refs';
        *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

sub CLONE_SKIP { 1 }

=head1 NAME

ZMQ::Raw::Message - ZeroMQ Message class

=head1 VERSION

version 0.22

=head1 DESCRIPTION

A L<ZMQ::Raw::Message> represents a ZeroMQ message.

=head1 SYNOPSIS

	use ZMQ::Raw;

	my $msg = ZMQ::Raw::Message->new;
	$msg->data ('hello');

	$socket->sendmsg ($msg);

=head1 METHODS

=head2 new( )

Create a new empty ZeroMQ message.

=head2 clone( )

Create a copy of a ZeroMQ message.

=head2 data ([$data])

Retrieve or set the message data.

=head2 more( )

Check if this message is part of a multi-part message, and if there are further
parts to be received.

=head2 size( )

Get the size in bytes of the content of the messsage.

=head2 routing_id( [$id] )

Get or set the routing id of the socket. To get a valid routing id, you must
receive a message from a C<ZMQ_SERVER> socket.

=head2 group( [$group] )

Get or set the group socket.

=head2 get( $property )

Get the value of C<$property>.

=head2 gets( $property )

Get metadata property.

=head1 CONSTANTS

=head2 ZMQ_MORE

=head2 ZMQ_SHARED

=head2 ZMQ_MSG_PROPERTY_ROUTING_ID

=head2 ZMQ_MSG_PROPERTY_SOCKET_TYPE

=head2 ZMQ_MSG_PROPERTY_USER_ID

=head2 ZMQ_MSG_PROPERTY_PEER_ADDRESS

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of ZMQ::Raw::Message
