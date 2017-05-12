package Netscape::Server::Socket;

# -------------------------------------------------------------------
#   Socket.pm - Netscape httpd/client socket class
#
#   Copyright (C) 1998 Benjamin Sugars
#
#   This is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself.
#
#   This software is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this software. If not, write to the Free Software
#   Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
# -------------------------------------------------------------------

use Netscape::Server qw/:all/;
use strict;

# --- Used to tie a file handle to a socket connection

sub TIEHANDLE {
    # --- Constructor
    my($class, $sn, $rq) = @_;
    ref($sn) or
	return;
    my $socket = {
	'session' => $sn,
	'request' => $rq,
	'header' => '',
	'header sent' => '',
    };
    bless($socket, $class);
}

sub PRINT {
    # --- Basically we just accumulate information until we get a blank line.
    # --- At that point we protocol_start_response and the rest of the stuff
    # --- gets sent to the client via net_write.
    my($self, @stuff) = @_;
    
    # --- Have we sent the header yet?
    if ($self->{'header sent'}) {
	$self->{'session'}->net_write(join('', @stuff));
    } else {
	$self->_send_header(@stuff);
    }
}

sub PRINTF {
    my($self, $format, @stuff) = @_;
    $self->PRINT(sprintf($format, @stuff));
}

sub READ {
    # --- Skip over the second parameter since we're writing to it directly.
    my($self, $buffer, $length, $offset, $bytes_read);
    ($self, undef, $length, $offset) = @_;
    
    # --- Just read from the socket and return the number of bytes read
    $bytes_read = $self->{'session'}->sys_net_read($buffer, $length, $offset);
    $_[1] = $buffer;
    return $bytes_read;
}

#XXX need to implement
#sub GETC {
#}

#XXX need to implement
#sub READLINE {
#}

# --- Methods below here are probably private
sub _send_header {
    # --- Builds up an http response header and sends it when complete
    # --- Returns true when the header is complete.
    my($self, @stuff) = @_;
    my($header, $body, $line);

    # --- Check for a blank line.  This gets kind of ugly because
    # --- the text can be passed as a list if the dude wants.
    $self->{'header'} = join('', $self->{'header'}, @stuff);
    ($header, $body) = split(m/(?:\r\n\r\n|\n\n)/, $self->{'header'}, 2);

    if (defined $body) {
	# --- The presence of a body indicates the end of the header
	my $sn = $self->{'session'};
	my $rq = $self->{'request'};

	# --- Set the appropriate server variables
	foreach $line (split(m/(?:\r\n|\n)/, $header)) {
	    my($key, $value) = split(m/: +/, $line);
	    $key =~ tr/A-Z/a-z/;
	    $rq->srvhdrs($key, $value);
	}

	# --- Set the status
	$rq->protocol_status($sn, PROTOCOL_OK);

	# --- Start the response
	$rq->protocol_start_response($sn);

	# --- Send the content of the body
	$sn->net_write($body);

	# --- Mark the header as sent
	$self->{'header sent'} = 1;
    }

    return $self->{'header sent'};
}

1;

__END__


=head1 NAME

Netscape::Server::Socket - Netscape httpd/client socket class

=head1 SYNOPSIS

  use Netscape::Server::Socket;
  tie(*FILEHANDLE, 'Netscape::Server::Socket', $sn, $rq);

=head1 DESCRIPTION

Netscape::Server::Socket provides a perl implementation of the socket
connection between the Netscape httpd and clients connecting to the
server.  It is intended to be used by nsapi_perl modules that wish to
send or receive data to a client.

For the full details of nsapi_perl, see L<nsapi_perl>.  Suffice it to
say here that nsapi_perl provides a mechanism by which a Perl
interpreter is embedded into a Netscape server.  The NSAPI can then be
programmed to in Perl rather than in C.  This is achieved by placing
the appropriate hooks in the server configuration files; nsapi_perl
will then call whatever Perl subroutines you wish at various stages of
processing a request from a client.

The remainder of this document describes the usage and internals of
Netscape::Server::Socket.

=head1 USAGE

Users of Netscape::Server::Socket will generally want to tie a
filehandle to the class.  Subsequent transactions on that filehandle
will then read to or from the client.  Indeed, at this time, all of
Netscape::Server::Socket's class and instance methods are for use by
tie().

Generally, it is therefore sufficient to call tie() as follows

  tie(*FILEHANDLE, 'Netscape::Server::Socket', $sn, $rq);

*FILEHANDLE is the typeglob of the filehandle you wish to tie; $sn is an
instance of Netscape::Server::Session; $rq is an instance of
Netscape::Server::Request.

The above call will return an instance Netscape::Server::Socket if
successful.  Most likely you will not need to call instance methods on
this object.  Rather, you will let the magic of tie() call the
appropriate instance methods whenever a read or write is attempted on
the tied filehandle.

Currently the following actions on the tied filehandle are supported:

=over 4

=item print FILEHANDLE LIST

=item printf FILEHANDLE FORMAT, LIST

=item read FILEHANDLE,SCALAR,LENGTH,OFFSET

=item sysread FILEHANDLE,SCALAR,LENGTH,OFFSET

=back

At this time there is no support for reading from the filehandle using
the diamond operator or using getc().  In other words, doing a

  my $line = <FILEHANDLE>
  my $char = getc(FILEHANDLE);

for a tied FILEHANDLE will not work.

Most of you can stop reading at this point; if you're interested in
the internals of the module, read on.

=head1 METHODS

The user need not call these methods directly but can rely on the
magic of tie() to do that for them.  The methods are listed here for
completeness.

=head2 Constructor

=over 4

=item B<TIEHANDLE>

  my $socket = TIEHANDLE Netscape::Server::Socket, $sn, $rq;

The TIEHANDLE method returns an instance of Netscape::Server::Socket.
$sn is an instance of Netscape::Server::Session.  $rq is an instance
of Netscape::Server::Request.

=back

=head2 Instance Methods

=item B<PRINT>

  $socket->PRINT(@stuff);

Causes @stuff to be sent to the client.  Until a completely empty line
is received, the data is assumed to comprise the http header.
Subsequent data is assumed to comprise the http message body.  In
other words, things like

  $socket->PRINT("Content-type: text/plain\n",
                 "\n",
                 "This came from the server\n");

will work as expected.

=item B<PRINTF>

  $socket->PRINTF($format, @stuff);

Works like the perl built-in printf function, but sends the data to
the client.  This is just a wrapper around PRINT(), so it has the same
behaviour regarding the http header/body.

=item B<READ>

  $socket->READ($scalar, $length, $offset);

Attempts to read $length bytes of data from the body of the client's
request to the server starting at $offset.  Stores the results in
$scalar.  Returns the actual number of bytes read.

Note that this method does not read data from the header of the
client's request.  To do this, look at the Netscape::Server::Request
man page.

Note also that this method does not (yet) return undef in the case of
an I/O error.  This is an ugly bug that will be fixed in future
release.

=over

=head1 AUTHOR

Benjamin Sugars <bsugars@canoe.ca>

=head1 SEE ALSO

perl(1), perltie(3)

nsapi_perl, Netscape::Server::Session, Netscape::Server::Request

=cut
