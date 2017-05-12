package Wily::RPC;

=head1 NAME

Wily::RPC - Perl extension for the Wily RPC interface

=head1 SYNOPSIS

  use Wily::RPC;
  use Wily::Message;

  # opens a file in wily and exits when the window is destroyed

  my $wily = Wily::RPC->new();
  my $win = $wily->win('/tmp/file_to_edit', 1);
  $wily->attach($win, Wily::Message::WEdestroy);
  while (my $event = $wily->event()) {
      if ($event->{type} == Wily::Message::WEdestroy and
              $event->{window_id} == $win) {
          last;
      }
  }

=head1 DESCRIPTION

Provides an interface to the Wily, using the lower level Wily::Message
and Wily::Connect packages (which can also be used without this wrapper).

Most of the methods of the Wily::RPC may block for a short time, they write
a message to wily over a unix domain socket and then wait for wily to 
write a response message. Wily responds quickly, but if such things matter
you will have to use the lower level packages instead.

=cut

use v5.8;
use strict;
use warnings;
use Carp;

use Wily::Message;
use Wily::Connect;
use File::Temp qw/ :POSIX /;
use IO::Socket;

our $VERSION = '0.01';

=head2 Connecting To Wily

	$wily = Wily::RPC->new();

Connects to wily and returns a Wily::RPC object reference.

=cut
sub new {
	my $package = shift;
	my $self = {};
	$self->{s} = Wily::Connect::connect();
	$self->{buffer} = '';
	$self->{events} = [];
	$self->{replies} = {};
	return bless $self, $package;
}

=head2 Checking for events

	unless ($wily->would_block()) {
		# retrieve event...
	}

The would_block() method returns true if a call to the event() method
will block or false if there is an event waiting to be retrieved.

=cut
sub would_block {
	my $self = shift;
	return scalar @{$self->{events}}
}
=head2 Retrieving an event

	$event = $wily->event();

The event() method returns a Wily::Message object representing
an event wily has sent. This method will block until an event
arrives (and if no events have been attached to, will thus block
for a very long time...).

Returns undef if the connection to Wily drops or errors.

=cut
sub event {
	my $self = shift;
	while (not @{$self->{events}}) {
		$self->read_socket() or return;
	}
	return pop @{$self->{events}};
}

=head2 Bouncing an event

	$wily->bounce($event);

The bounce() method sends an event back to wily for the standard
wily handling. This is commonly used with exec events, for example,
when your program only cares about the commands it understands and
bounces back the exec events it doesn't understand for wily to handle.

=cut
sub bounce {
	my $self = shift;
	my $msg = shift;
	if ($self->{type} > Wily::Message::WEfencepost) {
		return;
	}
	my $flat = $msg->flatten();
	if ($self->{s}->syswrite($flat) != length($flat)) {
		$self->{s}->close();
		croak "Write to wily failed";
	}
	return 1;
}

=head2 Listing existing windows

	$window_list = $wily->list();

The list() method returns a string that contains a line for each window
open in wily. Each line consists of the window name followed by whitespace
and the window ID number (which is used to specify a window in many other
methods).

On failure (I'm not sure how a list message could fail) undef is returned
and the error message placed in $wily->{error}.

=cut
sub list {
	my $self = shift;
	my $msg = $self->send(Wily::Message->new(Wily::Message::WMlist));
	if ($msg->{type} == Wily::Message::WRerror) {
		$self->{error} = $msg;
		return;
	}
	return $msg->{s};
}

=head2 Getting the supported wily features

	$features = $wily->features();

The features() method returns a string containing a whitespace seperated list of
features that the wily instance supports. Note, that not all wily instances support
this, and will result in an error (in which case only the standard wily messages
are supported).

On failure undef is returned and the error message placed in $wily->{error}.

=cut
sub features {
	my $self = shift;
	my $msg = $self->send(Wily::Message->new(Wily::Message::WMgetfeatures));
	if ($msg->{type} == Wily::Message::WRerror) {
		$self->{error} = $msg;
		return;
	}
	return $msg->{s};
}

=head2 Creating a window

	$win_id = $wily->win($name $backup)

The win() method causes wily to open a window with the pathname set to $name and returns the ID
number of that window. If $backup is 1 then
wily will keep backups for the window and enable the dirty indicator. If a window with the same
name already exists then the value of $backup is ignored and the ID number of the existing
window is returned.

On failure undef is returned and the error message placed in $wily->{error}.

=cut
sub win {
	my $self = shift;
	my ($name, $backup) = @_;
	my $msg = $self->send(Wily::Message->new(Wily::Message::WMnew, 0, 0, 0, $backup, $name));
	if ($msg->{type} == Wily::Message::WRerror) {
		$self->{error} = $msg;
		return;
	}
	return $msg->{window_id};
}

=head2 Reading window text

	$text = $wily->read($win_id, $p0, $p1);

The read() method returns the text in the character range [$p0, $p1) of the specified
window. Note, that the text includes the character at $p0 but does not include the
character at $p1.

On failure undef is returned and the error message placed in $wily->{error}.

=cut
sub read {
	my $self = shift;
	my ($window, $p0, $p1) = @_;
	my $msg = $self->send(Wily::Message->new(Wily::Message::WMread, $window, $p0, $p1));
	if ($msg->{type} == Wily::Message::WRerror) {
		$self->{error} = $msg;
		return;
	}
	return $msg->{s};
}

=head2 Searching

	($win_id, $r0, $r1) = $wily->goto($window_id, $p0, $p1, $search, $set_dot);

The goto() method causes wily to act as if the user had selected the text $search with
B3 in the window with ID number $window_id. If this results in a search then the search starts
from the position indicated by the range [$p0, $p1) - if $p0 > $p1 then the search starts
from the current selection. If $set_dot is 1 then wily will select the resulting selection and
warp the mouse cursor to it. Returns the window ID number and the range in that window found
by the search. This may be a different window (if the search text was a file name, for example).

$search can be plain text to search for or an address that wily understands, or a wily
regular expression search - anything which works when B3ed.

On failure () is returned and the error message placed in $wily->{error}.

=cut
sub goto {
	my $self = shift;
	my ($window, $p0, $p1, $s, $set_dot) = @_;
	my $msg = $self->send(Wily::Message->new(Wily::Message::WMgoto, $window, $p0, $p1, $set_dot, $s));
	if ($msg->{type} == Wily::Message::WRerror) {
		$self->{error} = $msg;
		return;
	}
	return ($msg->{window_id}, $msg->{p0}, $msg->{p1});
}

=head2 Getting the window name

	$name = $wily->get_name($win_id);

The get_name() method returns the name of the window with the specified ID number.

On failure undef is returned and the error message placed in $wily->{error}.

=cut
sub get_name {
	my $self = shift;
	my ($window) = @_;
	my $msg = $self->send(Wily::Message->new(Wily::Message::WMgetname, $window));
	if ($msg->{type} == Wily::Message::WRerror) {
		$self->{error} = $msg;
		return;
	}
	return $msg->{s};
}

=head2 Getting the window tools

	$tools = $wily->get_tools($win_id);

The get_tools() method returns the text of the tools in the tag of the specified window.

On faiure undef is returned and the error message placed in $wily->{error}.

=cut
sub get_tools {
	my $self = shift;
	my ($window) = @_;
	my $msg = $self->send(Wily::Message->new(Wily::Message::WMgettools, $window));
	if ($msg->{type} == Wily::Message::WRerror) {
		$self->{error} = $msg;
		return;
	}
	return $msg->{s};
}

=head2 Replacing text

	$wily->replace($win_id, $p0, $p1, $text);
	
The replace() method replaces the text in the range [$p0, $p1) in the window with ID number
$win_id with $text. A true value is returned upon success. If $p0==$p1 the text is inserted
at position $p0.

On failure undef is returned and the error message placed in $wily->{error}.

=cut
sub replace {
	my $self = shift;
	my ($window, $p0, $p1, $s) = @_;
	return $self->_simple_send(Wily::Message::WMreplace, $window, $p0, $p1, 0, $s);
}

=head2 Executing commands

	$wily->execute($win_id, $cmd);

The execute() method causes wily to act as if $cmd was selected with B2 in the window with
ID number $win_id. Returns 1 upon success.

On failure undef is returned and the error message placed in $wily->{error}.

=cut
sub execute {
	my $self = shift;
	my ($window, $s) = @_;
	return $self->_simple_send(Wily::Message::WMexec, $window, 0, 0, 0, $s);
}

=head2 Attaching

	$wily->attach($win_id, $mask);

The attach() method causes wily to send the requested events for the specified window
to the program. $mask should be a bitwise or (or just a sum) of the WE* constants 
in the Wily::Message package. If 'detach' is in the list of features returned by
the features() method then attach() can be called multiple times to recieve additional
event types.

WEexec and WEgoto events are sent to the client vefore they are processed by wily, if
you want wily to process them they need to be bounce()d back to wily.

The events will be made available via the event() method. 

Returns 1 on success, on failure undef is returned and the error message is placed in
$wily->{error}.

=cut
sub attach {
	my $self = shift;
	my ($window, $mask) = @_;
	return $self->_simple_send(Wily::Message::WMattach, $window, 0, 0, $mask);
}

=head2 Detaching

	$wily->detach($win_id, $mask);

The detach() method causes wily to stop sending the specified events for the specified window
to the program. $mask should be a bitwise or (or just a sum) of the WE* constants 
in the Wily::Message package.

Note, that this is not part of the "standard" wily message set and hence you should
make sure to handle a failure when dealing with wily instances that don't support
this function. Wily instances that do support this function will include 'detach' in
the feature list returned by the features() method.

Returns 1 on success, on failure undef is returned and the error message is placed in
$wily->{error}.

=cut
sub detach {
	my $self = shift;
	my ($window, $mask) = @_;
	return $self->_simple_send(Wily::Message::WMdetach, $window, 0, 0, $mask);
}

=head2 Setting the window name

	$wily->set_name($win_id, $name);

The set_name() method sets the name of the specified window to $name.

Returns 1 on success, on failure undef is returned and the error message is placed in
$wily->{error}.

=cut
sub set_name {
	my $self = shift;
	my ($window, $name) = @_;
	return $self->_simple_send(Wily::Message::WMsetname, $window, 0, 0, 0, $name);
}

=head2 Setting the window tools

	$wily->set_tools($win_id, $tools);

The set_tools() method sets the tools in the tag  of the specified window to $tools.

Returns 1 on success, on failure undef is returned and the error message is placed in
$wily->{error}.

=cut
sub set_tools {
	my $self = shift;
	my ($window, $tools) = @_;
	return $self->_simple_send(Wily::Message::WMsettools, $window, 0, 0, 0, $tools);
}

sub _simple_send {
	my $self = shift;
	my $msg = $self->send(Wily::Message->new(@_));
	if ($msg->{type} == Wily::Message::WRerror) {
		$self->{error} = $msg;
		return;
	}
	return 1;
}

=head2 Sending a message

	$result = $wily->send($msg);

The send() method is passed a Wily::Message object which is sent to wily. The response
message that will be sent by wily is then returned.

This method is not usually used, but could be useful if you wish to send a message 
that has been added to wily but is not available through the other methods.

=cut
sub send {
	my $self = shift;
	my $msg = shift;

	$msg->{message_id} = $self->{message_id}++;
	my $flat = $msg->flatten();
	if ($self->{s}->syswrite($flat) != length($flat)) {
		$self->{s}->close();
		croak "Write to wily failed";
	}
	while (not exists $self->{replies}{$msg->{message_id}}) {
		$self->read_socket() or croak "Read from wily failed";
	}
	$msg = $self->{replies}{$msg->{message_id}};
	delete $self->{replies}{$msg->{message_id}};
	return $msg;
}

=head2 Reading from wily

	$wily->read_socket()

The read_socket() method will read from the connection to wily. This is necessary in
order to retrieve events that have been attach()ed for. This method is needed if you
wish to avoid extended blocking which can result when calling event(). The
socket can be accessed via $wily->{s} and then the perl select function (or some other
mechanism) used to determine that a read won't block, at which point read_socket() can
safely be called and the would_block() used to determine if a complete event was read.

Note: this method will block if the socket does not have data ready (so check first
if that is an issue).

=cut
sub read_socket {
	my $self = shift;
	my $res = $self->{s}->sysread($self->{buffer}, 128, length($self->{buffer}));
	while (Wily::Message::complete_message($self->{buffer})) {
		my $msg = Wily::Message->new(0);
		$self->{buffer} = $msg->from_string($self->{buffer});
		if ($msg->{type} < Wily::Message::WEfencepost) {
			push @{$self->{events}}, $msg;
		} else {
			$self->{replies}{$msg->{message_id}} = $msg;
		}
	}
	return $res;
}

1;
__END__

=head2 EXPORT

None.

=head1 SEE ALSO

wily(1), Wily::Connect, Wily::Message

http://sam.holden.id.au/software/plwily/

=head1 AUTHOR

Sam Holden, E<lt>sam@holden.id.auE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Sam Holden


This module is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 1, or (at your option) any later version,

or

b) the "Artistic License" which comes with this module.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
module, in the file ARTISTIC.  If not, I'll be glad to provide one.

You should also have received a copy of the GNU General Public License
along with this program in the file named "Copying". If not, write to the
Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
02111-1307, USA or visit their web page on the internet at
http://www.gnu.org/copyleft/gpl.html.

=cut
