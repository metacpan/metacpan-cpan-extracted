#
# $Id: Access.pm,v 1.31 2003/03/02 11:12:09 dsw Exp $
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
# The JUNOS::Access package is meant to isolate the various access
# methods from the rest of the code.
#

package JUNOS::Access;

use strict;
use JUNOS::Trace;
use IO::Socket;
use IO::Pty;

#
# POSIX::Termios is an odd API; we need to create a 'termios'
# controller to pass all the requests thru. A single controller
# can be used against a number of handles, so we'll go ahead and
# make one up front.
#
use POSIX qw(:termios_h setsid);
use vars qw($termios);

BEGIN {
    $termios = new POSIX::Termios;
}

sub new
{
    my($class, $args) = @_;
    my %args = %$args;
    my $self = { %args };
    $self->{JUNOS_Device} = $args;

    $class = ref $class || $class;
    my $access = $args{access};
    if ($args{access}) {
	$access =~ s/-/_/g;
    }

    $class .= "::" . $access if $access;

    bless $self, $class;
}

sub start
{
    my($self) = @_;
    $self->{JUNOS_Device}->report_error("no " . ref $_[0] . "::start defined");
    undef;
}

sub connect
{
    my($self, %args) = @_;

    tracept("IO");
    $self->start(%args);
}

sub disconnect
{
    my($self) = @_;
    my($dead, $deadline);
    my $kid = $self->{PID};

    if( $self->{INPUT} ) { close($self->{INPUT}); }
    if( $self->{OUTPUT} ) { close($self->{OUTPUT}); }
    $self->{INPUT} = undef;
    $self->{OUTPUT} = undef;

    # Wait 5 seconds for the child to die a natural death.
    for ($deadline = time() + 5; $deadline < time();) {
	$dead = waitpid($kid, &WNOHANG);
	return 1 if $dead == $kid;
	sleep 1;
    }

    # Ask nicely...
    return 1 if kill("TERM", $kid) == 0;

    # Wait 10 seconds to see if they've got manners.
    for ($deadline = time() + 10; $deadline < time();) {
	$dead = waitpid($kid, &WNOHANG);
	return 1 if $dead == $kid;
	sleep 1;
    }

    # No more Mister Nice Guy....
    return 1 if kill("KILL", $kid) == 0;

    # Wait 15 seconds for the real death....
    for ($deadline = time() + 15; $deadline < time();) {
	$dead = waitpid($kid, &WNOHANG);
	return 1 if $dead == $kid;
	sleep 1;
    }

    # Nothing worked. Sigh...
    return undef;
}

sub send
{
    my($self, @data) = @_;
    my $data = join("", @data);

    trace("IO", "send: [[[[[$data]]]]]");
    tracept("IO");

    return if (!$self->{OUTPUT});

    #$self->{send_data} .= $data;
    #print "SEND: $data\n";
    my $rc = syswrite($self->{OUTPUT}, $data, length($data));
    $self->{seen_eof} = 1 if $rc <= 0;
    $rc;
}

sub recv
{
    my($self, $timeout) = @_;
    my $data;

    tracept("IO");
    return if (!$self->{INPUT});
    #print "SSF:\n",$self->{send_data},"\n";
    #print "Going to sysread...\n";
    my $len = sysread($self->{INPUT}, $data, 0x2000);
    #print "Done  sysread $len\n";

    $self->{seen_eof} = 1 if $len < 0;
    $self->{seen_eof} = 1 if $len == 0 && eof($self->{INPUT});
    if ($len == 0) {
        $self->{JUNOS_Device}->report_error("recv failed: " . (eof($self->{INPUT}) ? "EOF" : "dead"));
  	return;
    }

    #print "RECV: $data\n";
    trace("IO", "recv: $len [[[[[$data]]]]]");

    $data;
}

#
# Have we hit end-of-file yet?
#
sub eof
{
    my($self) = @_;

    $self->{seen_eof};
}

#
# start a command using unix-domain socket pairs; not currently used
#
sub start_command_sockets
{
    my $self = shift;

    tracept("IO");

    my($s1a, $s1b) = IO::Socket->socketpair(AF_UNIX, SOCK_STREAM, 0);
    my($s2a, $s2b) = IO::Socket->socketpair(AF_UNIX, SOCK_STREAM, 0);

    my $pid = fork;
    if ($pid < 0) {
        $self->{JUNOS_Device}->report_error("fork failed");
	return;
    } elsif ($pid == 0) {
	trace("Child", "Child $pid/", $$, " cmd: ", join(" ", @_));
	trace("Child", "Child FH: ", fileno($s1a), "/", fileno($s2a));

        open(STDIN, "<&=" . fileno($s1a)) || die "dup of stdin failed";
        open(STDOUT, ">&=" . fileno($s2a)) || die "dup of stdout failed";
        open(STDERR, ">&STDOUT") || die "dup of stderr failed";

	shutdown($s1a, 1);
	close($s1b);
	shutdown($s2a, 0);
	close($s2b);

	exec @_;
	die;

    } else {

	close($s1a);
	shutdown($s1b, 0);
	close($s2a);
	shutdown($s2b, 1);

	$self->{INPUT} = $s2b;
	$self->{OUTPUT} = $s1b;
    }

    1;
}

#
# Initialize a tty's termio setting: turn off echo.
#
sub init_tty
{
    my($self, $fd) = @_;

    unless ($termios->getattr(fileno($fd))) {
        $self->{JUNOS_Device}->report_error("getattr failed on pty");
	return;
    }
    my $lflags = $termios->getlflag;
    $lflags &= ~(&ECHO);
    $termios->setlflag($lflags);
    $termios->setattr(fileno($fd));
    1;
}

#
# Start a command in a sub-process under a pty
#
sub start_command
{
    my $self = shift;

    tracept("IO");

    my $pty = new IO::Pty;
    my $slave = $pty->slave;

    unless ($slave) {
        $self->{JUNOS_Device}->report_error("cannot create pty slave");
	return;
    }
	
    trace("IO", "Access: pty $pty $$pty ", $pty->ttyname);
    trace("IO", "Access: slv $slave $$slave ", $slave->ttyname);

    &init_tty($self, $slave) || return;

    my $pid = fork;
    if ($pid < 0) {
        $self->{JUNOS_Device}->report_error("fork failed");
	return;
    } elsif ($pid == 0) {
	trace("Child", "Child $pid/", $$, " cmd: ", join(" ", @_));
	trace("Child", "Child FH: ", fileno($pty), "/", fileno($slave));

	# Turn the pty/tty into our stdin/stdout/stderr
	close(STDIN);
	open(STDIN, "<&" . fileno($slave)) || die "dup of stdin failed";
	shutdown(STDIN, 1);
	close(STDOUT);
	open(STDOUT, ">&" . fileno($slave)) || die "dup of stdout failed";
	shutdown(STDOUT, 0);
	close(STDERR);
	open(STDERR, ">&STDOUT") || die "dup of stderr failed";

	#
	# We need to disassociate ourselves from the controlling tty.
	# It would be nice to make the pty/tty we just made into our
	# controlling tty, but this does not seem to be working....
	#
        setsid;

	# Close off the original pty/tty handles
	close($slave);
	close($pty);

	exec @_;
	die;

    } else {
	# Close off the slave side of pty/tty pair
	close($slave);

	# Record the pty side for later i/o
	$self->{INPUT} = $pty;
	$self->{OUTPUT} = $pty;
    }

    # Record the pid of the process we just made
    $self->{PID} = $pid;

    # If something bad happens kill this process off...
    $SIG{INT} = $SIG{__DIE__} = $SIG{HUP} = $SIG{TERM} = 
      sub { kill 9, $pid; exit };

    1;
}

sub incoming
{
    my($self) = @_;
    $self->{JUNOS_Device}->report_error("Unhandled incoming data");
    return;
}

#
# Implemented by subclass if necessary (xnm_auth stuff for instance)
#
sub authenticate {
    1;
}

1;

__END__

=head1 NAME

JUNOS::Access - Implement the Access Method superclass.  All Access Method
classes must subclass from JUNOS::Access.

=head1 SYNOPSIS

This example is extracted from Device.pm.  It creates an Access object
based on the access method type specified in $self (a reference to
a hash table containing information such as login, password, access
method type and destination hostname).  Then it starts a session with
the JUNOScript server at the destination host by calling the connect
method in the access object.  After the session is established, it 
goes on to perform the initial handshake with the JUNOScript server.

    my $conn = new JUNOS::Access($self);

    # Need better error handling here....
    ref($conn) || die "Could not open connection";

    # Record the connection; connect it, mark it
    $self->{JUNOS_Conn} = $conn;
    $conn->connect() || die "Could not connect";
    $self->{JUNOS_Connected} = 1;

    # Kick off the XML parser
    $self->parse_start();
    
    trace("Trace", "starting connect::\n");

    # We need to receive the server side of the initial handshake first
    # (at least the <?xml?> part), so that we can avoid sending our
    # handshake to the ssh processes initial prompts (password/etc).

    # So we wait til we see the start of the real XML data flow....
    until ($self->{JUNOS_Active}) {
        my $in = $conn->recv();
    
        my $waiting = 'waiting for xml';
        if( $conn->{seen_xml} ) { $waiting = 'found xml'; }
        trace("IO", "during connect - ($waiting) input:\n\t$in\n" );

        if ($conn->{seen_xml}) {
            # After we've seen xml, parse anything
        } elsif ($in =~ /<\s*\?/) {
            $in =~ s/^[\d\D]*(<\s*\?)/$1/;
            $conn->{seen_xml} = 1;
        } else {
            if (not $conn->incoming($in) or $conn->eof) {
                $self->disconnect;
                return undef;
            }
            next;
        }

        if ($conn->eof) {
            $self->parse_done($in);
            last;
        } else {
            $self->parse_more($in);
        }
    }

    # Send our half of the initial handshake
    my $xml_decl = '<?xml version="1.0" encoding="us-ascii"?>';
    my $junoscript = '<junoscript version="1.0" os="perl-api">';

    $conn->send($xml_decl . "\n" . $junoscript . "\n");

=head1 DESCRIPTION

This is an internal class used by JUNOS::Device only.  Its constructor
returns an access method class based on the access method specified by
JUNOS::Device.  If the access method 'telnet' is selected, an object
of class JUNOS::Access::telnet will be returned.  Once JUNOS::Device
has the reference to the new access method object, it uses it to 
make connection, and exchange information with the destination.

All access method classes (e.g. JUNOS::Access::telnet) must subclass
from JUNOS::Access.

=head1 CONSTRUCTOR

new($ARGS)

The constructor of JUNOS::Access simply looks at the access method type
and creates and returns an object of class JUNOS::Access::<access_method> 
(e.g. JUNOS::Access::telnet).  $CLASS is the prefix for the access
method class, "$CLASS::$access".  $ARGS is the reference to a hash 
table containing the type of the access method, this hash table is 
supplied by the application while calling the constructor of JUNOS::Device.


=head1 METHODS

connect(%ARGS)

This method is called to start a session with the destination host.
Internally, this method simplies calls the start method which is
always overloaded by the subclass.

ARGS is a hash table containing additional input parameters to 
establish the session.  See the individual access method subclass
to see if additional iput parameters are accepted.

disconnect()

shutdown the underlying mechanics and free/destory them.  This
method should be overloaded by the subclass.  If not overloaded,
it simplies kill the process that it started for the current 
session, which works for telnet and rsh.

eof()

Has the end-of-file been seen?

incoming()

Feed data back to the access method when JUNOS::Device finds something 
that it doesn't understand.  This is to have the access method object
parse the connection specific messages, such as 'Host not found'.
These messages are specific to the access method type so the incoming
method is always overridden by the subclass.  If the underlying code
used by the subclass already deals with errors in connect(), recv()
or send(), then this can be a NOP method.

recv()

read the next chunk of data.

send($DATA)

send data to the JUNOScript server.

start(%ARGS)

To be overloaded by subclass to start the underlaying mechanics
to open a session with the JUNOScript server at the destination.

ARGS is a hash table containing additional input parameters to 
establish the session.  See the individual access method subclass
to see if additional iput parameters are accepted.

start_command($ACCESS, @FLAGS, $WHO, $EXEC)

This method is called by the subclass of JUNOS::Access to start
a telnet or rsh session.

start_command_sockets()

This method is called by the subclass to start a command using 
unix-domain socket pairs; it is currently not used.

The following hash keys are used by JUNOS::Device.

seen_xml

Whether the <xml> element has been received.

seen_eof

Whether eof has been received.

=head1 SEE ALSO

    JUNOS::Device
    JUNOS::Access::rsh
    JUNOS::Access::ssh
    JUNOS::Access::ssl
    JUNOS::Access::telnet

=head1 AUTHOR

Juniper Junoscript Perl Team, send bug reports, hints, tips, and suggestions 
to support@juniper.net.

=head1 COPYRIGHT

Copyright (c) 2001 Juniper Networks, Inc.  All rights reserved.
