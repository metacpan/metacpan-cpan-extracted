#
# $Id: ssl.pm,v 1.10 2003/03/02 11:12:10 dsw Exp $
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
# ssl Access Method for the JUNOS::Access object
#
# Here are the mandatory input parameter(s) that are needed to 
# create a connection with the server and optional input parameters 
# that can change the default behavior of the SSL connection.
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
# 	specified, then the SSL connection will fail.
#
# $self->{ssl_port} = Optional.  The port number of the ssl server.  It's
# 	JUNOSCRIPT_SSL_PORT by default.
#
# $self->{ssl_cert_dir} = Optional.  The certificate dir storing the CA certs
#	validation of the server certificate.
#
# $self->{ssl_verify_method} = Optional.  A callback function provided by the 
# 	client application to verify the server certificate.
#
# $self->{ssl_client_cert} = Optional.  The file containing the client's 
# 	certificate.
#
# $self->{ssl_client_key} = Conditional on ssl_client_cert.  The file 
#	containing client's key.
#
# $self->{ssl_client_cipher_list} = Optional.  The list of ciphers the client
# 	will accept while negotiating with the server on the cipher suite 
#	for the new SSL connection.  This is a colon separated list, 
#       its syntax is specified in :
#       http://www.openssl.org/docs/apps/ciphers.html#CIPHER_LIST_FORMAT
#
# States maintained by this access method for each SSL connection, they
# can also be read by the client application:
#
# $self->{xnm_result} = contains the authenticated user if the SSL
#	connection was successful. Otherwise, it contains the error message.
#
# $self->{ssl_ctx} = the SSL_CTX object as framework for TLS/SSL enabled 
#	functions.
#
# $self->{ssl_conn} = the SSL structure for the connection
#
# $self->{ssl_socket} = the file handle of the socket attached to the SSLeay
# 	layer.
#
#==========================================================================
package JUNOS::Access::ssl;

use strict;
use IO::Socket;
use Net::SSLeay;
use XML::Parser;
use Term::ReadKey;
use JUNOS::Trace;
use JUNOS::Access;
use JUNOS::Access::xnm;
use vars qw(@ISA);
@ISA = qw(JUNOS::Access::xnm);

#
# JUNOS::Access::ssl::start
#
# Initialize SSLeay module and create a connection to $self->{hostname}
# The ssl port is JUNOSCRIPT_SSL_PORT unless $self->{ssl_port} is 
# already defined to a port number.
#
use constant JUNOSCRIPT_SSL_PORT => 3220;
my $ssl_initialized = 0;
sub start
{
    tracept("IO");
    my($self) = @_;

    # Only need to do this once for all SSL connections
    if ($ssl_initialized == 0) {
        Net::SSLeay::load_error_strings();
        Net::SSLeay::SSLeay_add_ssl_algorithms();
        Net::SSLeay::randomize();
        $ssl_initialized = 1;
    }

    # If port has not been defined, take the default port.
    my $port = $self->{ssl_port} || JUNOSCRIPT_SSL_PORT;

    my $dest_ip = gethostbyname($self->{hostname});
    unless ($dest_ip) {
	$self->{JUNOS_Device}->report_error("Cannot get ip address of $self->{hostname}: $!");
	return;
    }
    my $dest_serv_params = sockaddr_in($port, $dest_ip);
    unless ($dest_serv_params) {
	$self->{JUNOS_Device}->report_error("sockaddr_in failed: $!");
	return;
    }

    my $mysock = IO::Socket::INET->new(
                PeerAddr => $self->{hostname},
                PeerPort => $port,
                Proto => "tcp",
                Type => SOCK_STREAM,
    );

    unless ($mysock) {
	$self->{JUNOS_Device}->report_error("cannot create socket: $!");
	return;
    }
    $self->{ssl_socket} = $mysock;

    # use $|=1 to eleminate buffering on the socket
    $self->{ssl_socket}->autoflush(1);

    $self->{ssl_ctx} = Net::SSLeay::CTX_new();
    unless ($self->{ssl_ctx}) {
	$self->{JUNOS_Device}->report_error("Failed to create SSL_CTX: $!");
	trace("IO", "start: Failed to create SSL_CTX: " . Net::SSLeay::print_errs() . "\n");
	return;
    }

    if ($self->{ssl_client_cipher_list}) {
	trace("IO", "start: setting cipher list to $self->{ssl_client_cipher_list}\n");
	Net::SSLeay::CTX_set_cipher_list($self->{ssl_ctx}, $self->{ssl_client_cipher_list});
    }

    if ($self->{ssl_client_cert} && $self->{ssl_client_key}) {
    	unless (Net::SSLeay::set_cert_and_key($self->{ssl_ctx}, 
		$self->{ssl_client_cert}, $self->{ssl_client_key})) {
	    $self->{JUNOS_Device}->report_error("cannot set client certificate and key, $self->{ssl_client_cert}, $self->{ssl_client_key}: $!");
	    trace("IO", "start: Failed to set cert and key: " . Net::SSLeay::print_errs() . "\n");
	    return;
	    
	}
    }

    if ($self->{ssl_cert_dir}) {
        Net::SSLeay::CTX_load_verify_locations($self->{ssl_ctx}, '',
            $self->{ssl_cert_dir});
    }

    if ($self->{ssl_verify_method}) {
	Net::SSLeay::CTX_set_verify($self->{ssl_ctx}, 
	    &Net::SSLeay::VERIFY_PEER, $self->{ssl_verify_method});
    }

    # The network connection is now open, lets fire up SSL    
    $self->{ssl_conn} = Net::SSLeay::new($self->{ssl_ctx});
    unless ($self->{ssl_conn}) {
	$self->{JUNOS_Device}->report_error("Failed to create SSL: $!");
	trace("IO", "start: Failed to create SSL: " . Net::SSLeay::print_errs() . "\n");
	return;
    }

    # Must attach to SSLeay the underlying file descriptor (fileno) of 
    # the socket 
    Net::SSLeay::set_fd($self->{ssl_conn}, fileno($self->{ssl_socket})); 
    my $res = Net::SSLeay::connect($self->{ssl_conn});
    unless ($res) {
	$self->{JUNOS_Device}->report_error("Failed to create SSL connection: $!");
	trace("IO", "start: Failed to create SSL: " . Net::SSLeay::print_errs() . "\n");
	return;
    }

    trace("IO", "start: Connected to $self->{hostname}\n");
    trace("IO", "start: " . ssl_cipher_list($self->{ssl_conn}) . "\n");
    trace("IO", "start: Ciper '" . Net::SSLeay::get_cipher($self->{ssl_conn}) . "'\n");
    my $cert = Net::SSLeay::dump_peer_certificate($self->{ssl_conn});
    trace("IO", "start: Server Certificate: $cert\n");

    return $res;
}

#
# private: ssl_cipher_list
#
# This subroutine puts together all the cipher suites acceptable to both 
# the client and returns the list as a string.
#
sub ssl_cipher_list
{
    my $conn = shift;
    my $i = 0;
    my $p;
    my $cipher_list = "My Cipher List: \n";

    do {
	$p = Net::SSLeay::get_cipher_list($conn, $i);
        $cipher_list .= "    [$i] " . $p . "\n" if $p;
	$i++;
    } while $p;

    return $cipher_list;
}

#
# JUNOS::Access::ssl::send
#
# You can send an array of data buffers, this subroutine just concatenate
# them and send them all at once.
#
sub send
{
    tracept("IO");
    my($self, @data) = @_;
    return unless ($self->{ssl_conn});
    my $msg = join("", @data);
    my $res = Net::SSLeay::write($self->{ssl_conn}, $msg);
    unless ($res) {
	$self->{JUNOS_Device}->report_error("Failed to write data: $!");
	trace("IO", "send: Failed to write: " . Net::SSLeay::print_errs() . "\n");
	return;
    }
    $self->{seen_eof} = 1 if $res <= 0;
    trace("IO", "send: sent $res bytes:\n");
    trace("IO", "send: [[[[[$msg]]]]]\n");
    return $res;
}

#
# JUNOS::Access::ssl::recv
#
# This subroutine returns the data it receives.
#
sub recv
{
    tracept("IO");
    my $self = shift;
    return unless ($self->{ssl_conn});
    my $res = Net::SSLeay::read($self->{ssl_conn});  
    my $len = length($res) if $res;
    $self->{seen_eof} = 1 unless $res;
    $self->{seen_eof} = 1 if $len == 0 && eof($self->{ssl_conn});
    trace("IO", "recv: received $len bytes:\n");
    trace("IO", "recv: [[[[[$res]]]]]\n");
    return $res;
}

#
# JUNOS::Access::ssl::disconnect
#
# disconnect the SSL socket and free the context
#
sub disconnect
{
    tracept("IO");
    my($self) = @_;


    if ($self->{ssl_socket}) {
        close $self->{ssl_socket};
	undef($self->{ssl_socket});
    }

    if ($self->{ssl_conn}) {
        Net::SSLeay::free ($self->{ssl_conn});   # Tear down connection
        undef($self->{ssl_conn});
    }

    if ($self->{ssl_ctx}) {
        Net::SSLeay::CTX_free ($self->{ssl_ctx});
        undef($self->{ssl_ctx});
    }

    trace("IO", "disconnect: Disconnected from $self->{hostname}\n");
}

#
# JUNOS::Access::ssl::incoming
#
sub incoming
{
    $_[0];
}

1;

__END__

=head1 NAME

JUNOS::Access::ssl - Implements the ssl access method.

=head1 SYNOPSIS

This class is used internally to provide ssl access to a JUNOS::Access instance.

=head1 DESCRIPTION

This is a subclass of JUNOS::Access that manages a ssl session with the destination host.  The underlying mechanics for managing the ssl session is Net::SSLeay.

=head1 CONSTRUCTOR

new($ARGS)

See the description of the constructor of the superclass JUNOS::Access.  This class also reads the following ssl specific keys from the input hash table reference $ARGS.


    ssl_port			The port number of the ssl server.

    ssl_cert_dir		The certificate directory storing the
				CA certificates for server certification
				validation.

    ssl_verify_method		A callback function provided by the
				client application to perform specific
				validation on the server certificate.

    ssl_client_cert		The file containing the client's 
				certificate.

    ssl_client_key		The file containing the client's 
				key.

    ssl_client_cipher_list	The list of ciphers the client will
				accept while negotiating with the
				server on the cipher suite for the 
				new SSL session.  This is a colon
				separated list.  Its syntax is specified
				in:
	http://www.openssl.org/docs/apps/ciphers.html#CIPHER_LIST_FORMAT

=head1 SEE ALSO

    Net::SSLeay
    JUNOS::Access
    JUNOS::Device

=head1 AUTHOR

Juniper Junoscript Perl Team, send bug reports, hints, tips, and suggestions 
to support@juniper.net.

=head1 COPYRIGHT

Copyright (c) 2001 Juniper Networks, Inc.  All rights reserved.
