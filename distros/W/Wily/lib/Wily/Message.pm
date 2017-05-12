package Wily::Message;

use v5.8;
use strict;
use warnings;
use Carp;
use Encode qw/decode_utf8 encode_utf8/;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Wily::Message ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'constants' => [ qw(WEexec WEgoto WEdestroy WEreplace
	WEfencepost WRerror WMlist WRlist WMnew WRnew WMattach WRattach
	WMsetname WRsetname WMgetname WRgetname WMsettools WRsettools
	WMgettools WRgettools WMread WRread WMreplace WRreplace WMexec WRexec
	WMgoto WRgoto WMgetfeatures WRgetfeatures WMdetach WRdetach WMfencepost
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'constants'} } );

our $VERSION = '0.01';

use constant {
	# EVENTS (and event masks)
	WEexec => 1,
	WEgoto => 2,
	WEdestroy => 4,
	WEreplace => 8,

	WEfencepost =>9,

	# REQUESTS AND RESPONSES
	WRerror => 10,
	WMlist => 11,
	WRlist => 12,
	WMnew => 13,
	WRnew => 14,
	WMattach => 15,
	WRattach => 16,
	WMsetname => 17,
	WRsetname => 18,
	WMgetname => 19,
	WRgetname => 20,
	WMsettools => 21,
	WRsettools => 22,
	WMgettools => 23,
	WRgettools => 24,
	WMread => 25,
	WRread => 26,
	WMreplace => 27,
	WRreplace => 28,
	WMexec => 29,
	WRexec => 30,
	WMgoto => 31,
	WRgoto => 32,

	# Non-standard messages
	WMgetfeatures => 33,
	WRgetfeatures => 34,
	WMdetach => 35,
	WRdetach => 36,
								
	WMfencepost => 37,
};

our $COOKIE = 0xfeed;
our $HEADER_SIZE = 22;


sub new {
	my $package = shift;
	my ($type, $win, $p0, $p1, $flag, $s) = @_;
	for ($type, $win, $p0, $p1, $flag) {
		$_ = 0 unless defined;
	}
	$s = '' unless defined $s;

	my $self = {'type' => $type,
		'message_id' => 0,
		'window_id' => $win,
		'p0' => $p0,
		'p1' => $p1,
		'flag' => $flag,
		's' => $s
	};
	return bless $self, $package;
}

sub flatten {
	my $self = shift;
	return pack('nnNnnNNna'.(length($self->{s})+1), $COOKIE, 
		$self->{type}, $self->size(), $self->{message_id},
		$self->{window_id}, $self->{p0}, $self->{p1},
		$self->{flag}, encode_utf8($self->{s}));
}

sub size {
	my $self = shift;
	return $HEADER_SIZE + 1 + length(encode_utf8($self->{s}));
}

sub from_string {
	my $self = shift;
	my $msg = shift;
	my $size = _message_length($msg);
	my $cookie;
	($cookie, $self->{type}, undef, $self->{message_id}, $self->{window_id},
	$self->{p0}, $self->{p1}, $self->{flag}, $self->{s}) = 
		unpack('nnNnnNNna'.($size-1-$HEADER_SIZE), $msg);
	croak "Invalid Cookie" unless $cookie eq $COOKIE;
	$self->{s} = decode_utf8($self->{s});
	return $size<length($msg)?substr($msg, $size):'';
}


sub _message_length {
	my $buffer = shift;
	croak "Buffer shorter than header size" unless length($buffer) > $HEADER_SIZE;
	return unpack('N', substr($buffer, 4));
}

sub complete_message {
	my $buffer = shift;
	return length($buffer) > $HEADER_SIZE and
		length($buffer) >= _message_length($buffer);
}


1;
__END__

=head1 NAME

Wily::Message - Perl extension to handle Wily Messages

=head1 SYNOPSIS

  use Wily::Message;
  use Wily::Connect;

  # opens a file in wily and exits when the window is destroyed

  my $win_id;

  my $ws = Wily::Connect::connect();

  my $wm = Wily::Message->new(Wily::Message::WMnew, 0, 0, 0, 1,
      '/tmp/file_to_edit');
  $ws->syswrite($wm->flatten());

  my $buffer = '';
  until (Wily::Message::complete_message($buffer)) {
      $ws->sysread($buffer, 1024, length($buffer));
  }

  $buffer = $wm->from_string($buffer);

  if ($wm->{type} == Wily::Message::WRerror) {
      die "Error WMnew: $wm->{s}\n";
  } elsif ($wm->{type} == Wily::Message::WRnew) {
      $win_id = $wm->{window_id};
      $wm = Wily::Message->new(Wily::Message::WMattach, $win_id, 0, 0,
          Wily::Message::WEdestroy);
      $ws->syswrite($wm->flatten());
      until (Wily::Message::complete_message($buffer)) {
          $ws->sysread($buffer, 1024, length($buffer));
      }
      $buffer = $wm->from_string($buffer);
      if ($wm->{type} == Wily::Message::WRerror) {
           die "Error WMattach: $wm->{s}\n";
      } elsif ($wm->{type} == Wily::Message::WRattach) {
      } else {
          die "Expected a WRattach, but didn't get one";
      }
  } else {
      die "Expected a WRnew, but didn't get one";
  }

  while (1) {
      until (Wily::Message::complete_message($buffer)) {
           $ws->sysread($buffer, 1024, length($buffer));
      }
      $buffer = $wm->from_string($buffer);
      if ($wm->{type} == Wily::Message::WEdestroy and $wm->{window_id} == $win_id) {
          last;
      }
  }


=head1 DESCRIPTION

A simple object wrapper around Wily messages with a helper function
to assist in extracting messages from the wily connection.

=head2 Creating Messages

	$msg = Wily::Message->new($type, $window_id, $p0, $p1, $flag, $s);

This returns a new Wily::Message object setup according to the parameters.
All the parameters default to 0, except for $s which defaults to "". The
meaning of $flag and $s depend on the message type. $window_id specified the
id number of the wily window. $p0 and $p1 specify the range. Some of the
fields are not used by some of the messages.

See the Wily documentation for details about what messages are valid and
what they do.

=head2 Flattening a Message

	$bytes = $msg->flatten();

In order to send a message to Wily it must be flattened into a stream of
bytes. The flatten() method does this. Those bytes would then typicaly be
sent to Wily over the socket connection.

=head2 Size of a Message

	$size= $msg->size();

Returns the number of bytes that will be used by the flattened message.

=head2 Extracting a Message

	$msg = Wily::Message->new();
	$buffer = $msg->from_string($buffer);

The from_string() method extracts a message from the passed byte string,
the message object is modified to represent the flattened message
contained in the string. Any additional bytes in the string are returned.
The passed byte string must contain at least an entire flattened message,
or bad things will happen.

=head2 Testing for a Message

	if (Wily::Message::compete_message($buffer)) {
		$buffer = $msg->from_string($buffer);
	}

The complete_message function is passed a byte string and returns true
if a complete message is contained at the beginning of the string. It
returns false is there is no complete message. 

=head2 EXPORT

None by default.

Optionally the Message and Event constants can be exported.

=head1 SEE ALSO

wily(1), Wily::Connect

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
