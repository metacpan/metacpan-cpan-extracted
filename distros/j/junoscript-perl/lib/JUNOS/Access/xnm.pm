#
# $Id: xnm.pm,v 1.6 2003/07/09 19:36:05 trostler Exp $
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
# xnm Access Method: An abstract class for the TCP and SSL Access Methods
#
# Here are the mandatory input parameter(s) that are needed to 
# create a connection with the server and optional input parameters 
# that can change the default behavior of the TCP connection.
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
# 	specified, then the TCP connection will fail.
#
# Jade states maintained by this access method for each TCP/SSL connection, they
# can also be read by the client application:
#
# $self->{xnm_result} = contains the authenticated user if the TCP
#	connection was successful. Otherwise, it contains the error message.
#
# $self->{xnm_state} = the current state of the connection
#
# $self->{xnm_challenge} = the challenge prompt provided by the server
#
# $self->{xnm_response_element} = a very temporary variable to keep the name
#	of the element live just long enough so the xnm_auth_char can use
#       it.  It is set everytime, xnm_auth_start is called and unset by
#       xnm_auth_char after it knows which element the data is meant for.
#
#==========================================================================
package JUNOS::Access::xnm;

use strict;
use IO::Socket;
use XML::Parser;
use Term::ReadKey;
use JUNOS::Trace;
use JUNOS::Access;
use vars qw(@ISA);
@ISA = qw(JUNOS::Access);

#
# JUNOS::Access::xnm::start
#
use constant JUNOSCRIPT_XNM_NOECHO => 'no';
sub start
{
    # implemented by subclass
    return;
}

#
# private: xnm_authenticate
#
# This subroutine sends a login request to authenticate itself wit the server.
# If the response comes back with a challenge, it sends another login request 
# with the challenge response.
#
# <init> --> <sent> --> <challenge> --> <sent> --> <recvd> --> <authenticated>
#               |                                     |
#               |                                     |------> <failed>
#               V
#            <recvd>
#               |
#               |
#               V
#            -------
#            |     |
#            |     |
#            V     V
# <authenticated> <failed>
#
use constant XNM_STATE_INIT => "init";
use constant XNM_STATE_REQUEST_SENT => "sent";
use constant XNM_STATE_REPLY_RECEIVED => "recvd";
use constant XNM_STATE_CHALLENGE_REQUESTED => "challenge";
use constant XNM_STATE_AUTHENTICATED => "authenticated";
use constant XNM_STATE_AUTH_FAILED => "failed";

sub authenticate
{
    my($self) = @_;

    my $xnm_parser = new XML::Parser();
    unless ($xnm_parser) {
	$self->{JUNOS_Device}->report_error("Failed to create TCP parser: $!");
        return;
    }

    $xnm_parser->setHandlers(
	Start => \&xnm_auth_start, 
	Char => \&xnm_auth_char);

    my $data;

    # send our login request
    $self->xnm_send_login_request() || return;

    # check response
    $self->{xnm_state} = XNM_STATE_REQUEST_SENT;
    trace("IO", "xnm_authenticate: new state is $self->{xnm_state}\n");

    # Get rpc-reply
    $data = $self->recv() || return;

    # Get auth results
    trace("Getting authentication results");
    $data .= $self->recv();

    eval {
      unless ($xnm_parser->parse($data, access => $self)) {
	      $self->{JUNOS_Device}->report_error("cannot parse $data: $!");
	      return;
      }
    };
    return if $@;
	  return 1 if ($self->{xnm_state} eq XNM_STATE_AUTHENTICATED);

    $self->{JUNOS_Device}->report_error("authentication failed: $self->{xnm_result}");
    return;
}

#
# private: xnm_send_login_request
#
# This subroutine sends a TCP login request via the TCP socket.
#
#         <rpc>
#            <request-login>
#                <!-- AUTH PROTOCOL -->
#            </request-login>
#         </rpc>
#
# Where the AUTH PROTOCOL section from the client side may contain these tags:
#
#         <username>USERNAME</username>
#         <challenge-response>CHALLENGE-RESPONSE</challenge-response>
#
# At minimum the client MUST send the <username> tag with the login
# name whenever requesting authentication.
#
use constant XNM_XML_REQ_LOGIN =>"<rpc><request-login>%s</request-login></rpc>";
use constant XNM_XML_USER_INFO =>"<username>%s</username>";
use constant XNM_XML_CHALLENGE_INFO =>"<challenge-response>%s</challenge-response>";
sub xnm_send_login_request
{
    my($self) = @_;

    unless ($self->{login}) {
	if ($self->{noninteractive}) {
	    $self->{JUNOS_Device}->report_error("not allowed to prompt user for login name.");
	    return; 
	}
 	unless ($self->{login} = prompt_for_info('Login:', 1)) {
	    $self->{JUNOS_Device}->report_error("Cannot get login: $!");
	    return;
    	}
    }

    my $auth_info = sprintf(XNM_XML_USER_INFO, $self->{login});

    if ($self->{xnm_state} eq XNM_STATE_CHALLENGE_REQUESTED) {
	my $echotype = $self->{xnm_challenge_type} || JUNOSCRIPT_XNM_NOECHO;
	$echotype = ($echotype eq JUNOSCRIPT_XNM_NOECHO)?0:1; 
	my $prompt = $self->{xnm_challenge} || 'Password:';
	if ($self->{noninteractive}) {
	    $self->{JUNOS_Device}->report_error("not allowed to prompt user for $prompt.");
	    return; 
	}
	my $challenge_response = prompt_for_info($prompt, $echotype);
	print "\n";
	unless ($challenge_response) {
	    $self->{JUNOS_Device}->report_error("Cannot get challenge response: $!");
	    return;
	}
	$auth_info .= sprintf(XNM_XML_CHALLENGE_INFO, $challenge_response);
    } elsif ($self->{password}) {
	$auth_info .= sprintf(XNM_XML_CHALLENGE_INFO, $self->{password});
    }

    my $login_request = sprintf(XNM_XML_REQ_LOGIN, $auth_info);
  
    $self->send($login_request);
}

#
# prompt_for_info
#
# Prompt user for information.
#
sub prompt_for_info
{
    my($prompt, $echo) = @_;
    print "$prompt ";
    ReadMode 'noecho' unless $echo;
    my $data = ReadLine 0;
    ReadMode 'normal' unless $echo;
    chomp $data;
    return $data;
}

#
# Callback: xnm_auth_start
#
# This callback is called by $self->{xnm_parser} to parse the 
# login response to manage the authentication states.  It is
# called with the tag name and atttributes of an XML element
# in the login response.
#
# Excepted Response for TCP Authentication:
#
#         <rpc-reply>
#            <login-challenge>
#	         <challenge echo='no or yes'>
#                    <!-- PROMPT -->
#	         </challenge>
#            </login-challenge>
#         </rpc-reply>
# Or:
# 
#         <rpc-reply>
#            <status>
#                <!-- success of fail -->
#            </status>
#            <message>
#                <!-- username or error message -->
#            </message>
#         </rpc-reply>
# 
my %xnm_auth_start_state_table = ( 
	'status' => XNM_STATE_REPLY_RECEIVED,
	'challenge' => XNM_STATE_CHALLENGE_REQUESTED
);
sub xnm_auth_start
{
    my($parser, $element, %attrs) = @_;
    my $self = $parser->{access} || return;
    $self->{xnm_response_element} = $element;

    if ($xnm_auth_start_state_table{$element}) {
        $self->{xnm_state} = $xnm_auth_start_state_table{$element};
        if ($self->{xnm_state} eq XNM_STATE_CHALLENGE_REQUESTED) {
	    $self->{xnm_challenge_type} = $attrs{echo};
	}
        trace("IO", "xnm_auth_start: new state is $self->{xnm_state}\n");
    } 
}

#
# Callback: xnm_auth_char
#
# This callback is called by $self->{xnm_parser} to parse the 
# login response to manage the authentication states.  It's 
# called with the value of an XML element in the login response.
#
use constant XNM_RESPONSE_MESSAGE => 'message';
use constant XNM_SUCCESS_REPLY => "success";
sub xnm_auth_char
{
    my($parser, $data) = @_;
    my $self = $parser->{access} || return;

    if ($self->{xnm_state} eq XNM_STATE_REPLY_RECEIVED) {
        if ($data eq XNM_SUCCESS_REPLY) {
            $self->{xnm_state} = XNM_STATE_AUTHENTICATED;
        } else {
            $self->{xnm_state} = XNM_STATE_AUTH_FAILED;
        }
        trace("IO", "xnm_auth_char: new state is $self->{xnm_state}\n");
    } elsif ($self->{xnm_state} eq XNM_STATE_CHALLENGE_REQUESTED) {
        $self->{xnm_challenge} = $data;
    } elsif ($self->{xnm_response_element} eq XNM_RESPONSE_MESSAGE) {
	$self->{xnm_result} = $data;
    } 

    undef($self->{xnm_response_element}); # have dealt with this tag
}

#
# JUNOS::Access::xnm::incoming
#
sub incoming
{
    $_[0];
}

1;

__END__

=head1 NAME

JUNOS::Access::xnm - Implements the xnm access method which must be subclassed by any access method that talks to the xnm server (e.g. ssl and tcp).

=head1 SYNOPSIS

This class is used internally to provide xnm access to a JUNOS::Access instance. 

=head1 DESCRIPTION

This is a subclass of JUNOS::Access that manages a xnm session with the destination host.  

=head1 CONSTRUCTOR

new($ARGS)

See the description of the constructor of the superclass JUNOS::Access.


=head1 SEE ALSO

    JUNOS::Access
    JUNOS::Device

=head1 AUTHOR

Juniper Junoscript Perl Team, send bug reports, hints, tips, and suggestions 
to support@juniper.net.

=head1 COPYRIGHT

Copyright (c) 2001 Juniper Networks, Inc.  All rights reserved.
