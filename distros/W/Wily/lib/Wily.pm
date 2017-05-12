package Wily;

=head1 NAME

Wily - Perl extension for interfacing with Wily

=head1 SYNOPSIS

  use Wily;
  use Wily::Message;

  # opens a file in wily and exits when the window is destroyed

  my $wily = Wily->new();
  my $win = $wily->win('/tmp/file_to_edit', 1);
  $win->set_callback(Wily::Message::WEdestroy, sub {exit;});
  $win->attach(Wily::Message::WEdestroy);
  $wily->event_loop();

=head1 DESCRIPTION

Provides a reasonably high level OO interface to wily. A lower level
interface is available via Wily::RPC, and an even lower level one
through Wily::Message and Wily::Connect.

The actual windows in wily are represented by Wily::Win objects.

=head1 The Wily Objects

The following operations can be performed with a Wily object.

=cut

use v5.8;
use strict;
use warnings;

use Wily::RPC;
use Wily::Message;

our $VERSION = '0.02';

=head2 Creating a Wily object

	$wily = Wily->new();

Connects to wily and returns a Wily object.

=cut
sub new {
	my $package = shift;
	my $self = {};
	$self->{handle} = shift || Wily::RPC->new();
	$self->{wins} = {};
	return bless $self, $package;
}

=head2 The main event loop

	$wily->event_loop();

The event_loop() method never returns (unless the Wily connection breaks somehow),
incoming wily events will be dispatched to the appropriate Wily::Win objects.

=cut
sub event_loop {
	my $self = shift;
	while ($self->handle_event()) {
	}
}

=head2 Dispatching events

	$wily->event_non_block();

The event_non_block() method dispatches all pending events to the appropriate
Wily::Win objects, it won't block (unless the event handlers block) as it
will only dispatch events which have already been read from wily connection.

=cut
sub events_non_block {
	my $self = shift;
	$self->handle_event() while not $self->{handle}->would_block();
}

=head2 Dispatch an event

	$wily->handle_event()

Dispatches a single event to the appropriate Wily::Win object. Will block if no
events are pending.

Returns undef if the Wily connection breaks.

=cut
sub handle_event {
	my $self = shift;
	my $msg = $self->{handle}->event();
	return unless defined $msg;
	$self->{wins}{$msg->{window_id}}->event($msg);
	return 1;
}

=head2 Bouncing events

	$wily->bounce($event);

The bounce() method bounces an event back to wily, events which are not handled
should be sent back to wily so that the standard wily handling will be applied.

=cut
sub bounce {
	my $self = shift;
	$self->{handle}->bounce(@_);
}

=head2 Listing windows

	@windows = $wily->list();

The list() method returns a list of the windows wily has open, each element of 
the list is an array reference. The first entry of which is the name of the 
window, and the second entry of which is a Wily::Win object representing the
window.

=cut
sub list {
	my $self = shift;
	return map {[$_->[0], $self->win_from_id($_->[1])]} 
		map {[split /\t/, $_, 2]}
		split /\n/, $self->{handle}->list();
}

=head2 Getting the supported wily features

	@features = $wily->features();

The features() method returns a list of all the features supported by the instance of
wily that is connected to.

=cut
sub features {
	my $self = shift;
	return split ' ', $self->{handle}->features();
}

=head2 Create a window

	$win = $wily->win($name, $backup);

The win() method causes wily to open a window with the pathname set to $name and returns a
Wily::Win object repesenting the window. If $backup is 1 then wily will keep backups for the
window and enable the dirty indicator. If a window with the same name already exists then
the value of $backup is ignored and a reference to the existing window is returned.

On failure undef is returned.

=cut
sub win {
	my $self = shift;
	my $win = Wily::Win->new($self, @_);
	return unless $win;
	$self->{wins}{$win->{window_id}} = $win unless exists $self->{wins}{$win->{window_id}};
	return $self->{wins}{$win->{window_id}};
}

=head2 Get an existing window

	$win = $wily->win_from_id($id);

The win_from_id() method returns a Wily::Win object representing the wily window with an
id of $id. Note, that the existance of the window is not actually checked, so method calls
on the Wily::Win object may fail.

=cut
sub win_from_id {
	my $self = shift;
	my ($id) = @_;
	return $self->{wins}{$id} if exists $self->{wins}{$id};
	$self->{wins}{$id} = Wily::Win->new_from_id($self, $id);
	return $self->{wins}{$id};
}

=head2 Wily socket handle

	$socket = $wily->socket();

The socket() method returns the socket that connects to wily. This can be used in
order to check for the availablility of data when integrating with other data sources.

=cut
sub socket {
	my $self = shift;
	return $self->{handle}{s};
}

=head2 Read the wily socket

	$wily->read_socket();

Performs a read on the wily socket. This will block unless there is data available, so
usually you would call this after checking for the presence of data via something like
select.

=cut
sub read_socket {
	my $self = shift;
	$self->{handle}->read_socket();
}


package Wily::Win;

=head1 The Wily::Win Objects

The following operations can be performed with a Wily::Win object.

=head2 Creating Wily::Win objects

Wily::Win objects should be created through a Wily object (or as the result
of the goto() method of an existing Wily::Win object. See the Wily documentation
for details on how to do so.

=cut

use strict;
use warnings;
use Carp;

our $VERSION = '0.01';

sub new {
	my $package = shift;
	my ($wily, $name, $backup) = @_;
	my $self = {};
	$self->{wily} = $wily;
	$self->{window_id} = $wily->{handle}->win($name, $backup);
	$self->{callbacks} = {};
	return bless $self, $package;
}

sub new_from_id {
	my $package = shift;
	my ($wily, $id) = @_;
	my $self = { wily => $wily, window_id => $id, callbacks => {} };
	return bless $self, $package;
}

sub event {
	my $self = shift;
	my $event = shift;

	if (exists $self->{callbacks}{$event->{type}}) {
		$self->{callbacks}{$event->{type}}($event);
	} else {
		$self->{wily}->bounce($event);
	}
}

=head2 Attaching

	$win->attach($mask);

The attach() method causes wily to send the requested events. $mask should be a
bitwise or (or just a sum) of the WE* cnstants in the Wily::Message package. If
the wily instance supports the 'detach' feature then attach() can be called
multiple times to attach for additional events.

WEexec and WEgoto events are sent to the client vefore they are processed by wily, if
you want wily to process them they need to be bounce()d back to wily.

To handle the events you will need to regster a function to be called for the
event type with the set_callback() method.

Returns true on success and undef on failure.

=cut
sub attach {
	my $self = shift;
	$self->{wily}{handle}->attach($self->{window_id}, @_);
}

=head2 Detaching

	$win->detach($mask);

The detach() mehod causes wily to stop sending the specified events. $mask should be a
bitwise or (or just a sum) of the WE* cnstants in the Wily::Message package.

Note, that this is not part of the "standard" wily message set and hence you should
make sure to handle a failure when dealing with wily instances that don't support
this function.

Returns true on success and undef on failure.

=cut
sub detach {
	my $self = shift;
	$self->{wily}{handle}->detach($self->{window_id}, @_);
}

=head2 Getting the name

	$name = $win->get_name();

The get_name() method returns the name of the window.

On failure undef is returned.

=cut
sub get_name {
	my $self = shift;
	return $self->{wily}{handle}->get_name($self->{window_id}, @_);
}

=head2 Getting the tools

	$tools = $win->get_tools();

he get_tools() method returns the text of the tools in the window tag.

On faiure undef is returned.

=cut
sub get_tools {
	my $self = shift;
	return $self->{wily}{handle}->get_tools($self->{window_id}, @_);
}

=head2 Searching

	($win2, $r0, $r1) = $win->goto($p0, $p1, $search, $set_dot);

The goto() method causes wily to act as if the user had selected the text $search with
B3 in the window. If this results in a search then the search starts
from the position indicated by the range [$p0, $p1) - if $p0 > $p1 then the search starts
from the current selection. If $set_dot is 1 then wily will select the resulting selection and
warp the mouse cursor to it. Returns the window and the range in that window found
by the search. This may be a different window (if the search text was a file name, for example).

$search can be plain text to search for or an address that wily understands, or a wily
regular expression search - anything which works when B3ed.

On failure () is returned.

=cut
sub goto {
	my $self = shift;
	my @res = $self->{wily}{handle}->goto($self->{window_id}, @_);
	$res[0] = $self->{wily}->win_from_id($res[0]);
	return @res;
}

=head2 Reading text

	$text = $win->read($p0, $p1);

The read() method returns the text in the character range [$p0, $p1).
Note, that the text includes the character at $p0 but does not include the
character at $p1.

On failure undef is returned.

=cut
sub read {
	my $self = shift;
	return $self->{wily}{handle}->read($self->{window_id}, @_);
}

=head2 Replacing text

	$win->replace($p0, $p1, $text);

The replace() method replaces the text in the range [$p0, $p1) with $text. A true
value is returned on success, or undef on failure.

=cut
sub replace {
	my $self = shift;
	return $self->{wily}{handle}->replace($self->{window_id}, @_);
}

=head2 Executing commands

	$win->execute($cmd);

The execute() method causes wily to act as if $cmd was selected with B2 in the window.
A true value is returned on success, or undef on failure.

=cut
sub execute {
	my $self = shift;
	$self->{wily}{handle}->execute($self->{window_id}, @_);
}

=head2  Setting the tools

	$win->set_tools($tools);

The set_tools() method sets the tools in the tag of the window to $tools.
A true value is returned on success, or undef on failure.

=cut
sub set_tools {
	my $self = shift;
	$self->{wily}{handle}->set_tools($self->{window_id}, @_);
}

=head2 Setting the name

	$win->set_name($name);

The set_name() method sets the name of the window to $name.
A true value is returned on success, or undef on failure.

=cut
sub set_name {
	my $self = shift;
	$self->{wily}{handle}->set_name($self->{window_id}, @_);
}

=head2 Setting event callbacks

	$win->set_callback($event_type, $function);

Sets the callback for events of type $event_type to be $function. Whenever
an event of type $event_type is recieved it $function will be called
with the event as the only argument.

Note, to actually begin recieve events attach() must be used.

=cut
sub set_callback {
	my $self = shift;
	my ($type, $cb) = @_;
	$self->{callbacks}{$type} = $cb;
}

=head2 Removing event callbacks

	$win->remove_callback($event_type);

The callback for events of type $event_type will be removed.

=cut
sub remove_callback {
	my $self = shift;
	my ($type) = @_;
	delete $self->{callbacks}{$type};
}

=head2 Getting the window text

	$text = $win->get_body();

The get_body() method returns the text in the window body. This is just a wrapper
around goto() and read(). Returns undef on failure.

=cut
sub get_body {
	my $self = shift;
	my @goto = $self->goto(0, 0, ':,');
	return unless @goto;
	return $self->read($goto[1], $goto[2]);
}

=head2 Setting the window text

	$win->set_body($text);

The set_body() method sets the text in the body of the window to be $text. This is
just a wrapper around goto() and replace(). Returns undef on failure, true on success.

=cut
sub set_body {
	my $self = shift;
	my ($s) = @_;
	my @goto = $self->goto(0, 0, ':,');
	return unless @goto;
	$self->replace($goto[1], $goto[2], $s);
}

1;
__END__

=head2 EXPORT

None.



=head1 SEE ALSO

wily(1), Wily::Message, Wily::RPC, Wily::Connect

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
