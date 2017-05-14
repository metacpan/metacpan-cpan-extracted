#
# $Id: clear_text.pm,v 1.9 2003/03/02 11:12:10 dsw Exp $
#
# COPYRIGHT AND LICENSE
# Copyright (c) 2001-2003, Juniper Networks, Inc.  
# All rights reserved.  
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 	1.	Redistributions of source code must retain the above
# copyright notice, this list of conditions and the following
# disclaimer. 
# 	2.	Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution. 
# 	3.	The name of the copyright owner may not be used to 
# endorse or promote products derived from this software without specific 
# prior written permission. 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#

#==========================================================================
#
# clear-text Access Method for the JUNOS::Access object
#
# Here are the mandatory input parameter(s) that are needed to 
# create a connection with the server and optional input parameters 
# that can change the default behavior of the clear-text connection.
#
# $self->{hostname} = Mandatory.  Name of the router to connect to.
#
# $self->{login} = Conditional on noninteractive.  The username to login the server.
# 	If this parameter is not provided by the client application,
# 	this module will prompt for the username unless noninteractive
# 	is specified.
#
# $self->{password} = Conditional on noninteractive.  The password for the username.
# 	If this parameter is not provided by the client
# 	application and it's requested by the server, this
# 	module will prompt for the password unless noninteractive
# 	is specified.
#
# $self->{noninteractive} = Optional.  If this parameter is specified, this module
# 	will not prompt for any information it needs.  Instead,
# 	it will fail if any required information is not already
# 	provided by the client application.  For example, if
# 	the login value is not provided and noninteractive is
# 	specified, then the clear-text connection will fail.
#
# $self->{clear_text_port} = Optional.  The port number of the clear-text server.  It's
# 	JUNOSCRIPT_CLEAR_TEXT_PORT by default.
#
# States maintained by this access method for each clear-text connection, they
# can also be read by the client application:
#
# $self->{xnm_result} = contains the authenticated user if the clear-text
#	connection was successful. Otherwise, it contains the error message.
#
# $self->{clear_text_socket} = the file handle of the socket attached to the clear-text
# 	layer.
#
#==========================================================================
package JUNOS::Access::clear_text;

use strict;
use IO::Socket;
use XML::Parser;
use Term::ReadKey;
use JUNOS::Trace;
use JUNOS::Access;
use JUNOS::Access::xnm;
use vars qw(@ISA);
@ISA = qw(JUNOS::Access::xnm);

#
# JUNOS::Access::clear_text::start
#
# Initialize and create a connection to $self->{hostname}
# The clear_text port is JUNOSCRIPT_CLEAR_TEXT_PORT unless $self->{clear_text_port} is 
# already defined to a port number.
#
use constant JUNOSCRIPT_CLEAR_TEXT_PORT => 3221;
sub start
{
    tracept("IO");
    my($self) = @_;

    # If port has not been defined, take the default port.
    my $port = $self->{clear_text_port} || JUNOSCRIPT_CLEAR_TEXT_PORT;

    my $mysock = IO::Socket::INET->new(
		PeerAddr => $self->{hostname},
		PeerPort => $port,
		Proto => "tcp",
		Type => SOCK_STREAM,
    );

    unless ($mysock) {
	$self->{JUNOS_Device}->report_error("cannot create socket : $!");
	return;
    }
    $self->{clear_text_socket} = $mysock;

    # use $|=1 to eleminate buffering on the socket
    $self->{clear_text_socket}->autoflush(1);

    trace("IO", "start: Connected to $self->{hostname}\n");

    return 1;
}


#
# JUNOS::Access::xnm::send
#
# You can send an array of data buffers, this subroutine just concatenate
# them and send them all at once.
#
sub send
{
    tracept("IO");
    my($self, @data) = @_;
    return unless ($self->{clear_text_socket});
    my $msg = join("", @data);
    my $res = $self->{clear_text_socket}->send($msg);
    unless ($res) {
        $self->{JUNOS_Device}->report_error("Failed to write data: $!");
        trace("IO", "send: Failed to write \n");
        return;
    }
    trace("IO", "send: sent $res bytes:\n");
    trace("IO", "send: [[[[[$msg]]]]]\n");
    return $res;
}
     
#
# JUNOS::Access::xnm::recv
#
# This subroutine returns the data it receives.
#
sub recv
{
    tracept("IO");
    my $self = shift;
    my $data;
    return unless ($self->{clear_text_socket});
    $self->{clear_text_socket}->recv($data, 1024);
    my $len = length($data)if $data;
    trace("IO", "recv: received $len bytes:\n");
    trace("IO", "recv: [[[[[$data]]]]]\n");
    return $data;
}

#
# disconnect the clear-text socket and free the context
#
sub disconnect
{
    tracept("IO");
    my($self) = @_;


    if ($self->{clear_text_socket}) {
        close $self->{clear_text_socket};
	undef($self->{clear_text_socket});
    }

    trace("IO", "disconnect: Disconnected from $self->{hostname}\n");
}

#
# JUNOS::Access::clear_text::incoming
#
sub incoming
{
    $_[0];
}

1;

__END__

=head1 NAME

JUNOS::Access::clear_text - Implements the clear-text access method.

=head1 SYNOPSIS

This class is used internally to provide clear-text access to a JUNOS::Access
instance.

=head1 DESCRIPTION

This is a subclass of JUNOS::Access that manages a clear text session with the destination host.  The underlying mechanics for managing the clear text session is IO::Socket.

=head1 CONSTRUCTOR

new($ARGS)

See the description of the constructor of the superclass JUNOS::Access.  This class also reads the following clear_text specific keys from the input hash table reference $ARGS.


    clear_text_port			The port number of the clear-text server.

=head1 SEE ALSO

    JUNOS::Access
    JUNOS::Device

=head1 AUTHOR

Juniper Junoscript Perl Team, send bug reports, hints, tips, and suggestions 
to support@juniper.net.

=head1 COPYRIGHT

Copyright (c) 2001 Juniper Networks, Inc.  All rights reserved.
