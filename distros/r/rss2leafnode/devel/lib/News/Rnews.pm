# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015 Kevin Ryde
#
# This file is part of RSS2Leafnode.
#
# RSS2Leafnode is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# RSS2Leafnode is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with RSS2Leafnode.  If not, see <http://www.gnu.org/licenses/>.

package News::Rnews;
use 5.008; # for multi-arg pipe open()
use strict;
use warnings;
use Carp;

our $VERSION = 79;

use constant DEBUG => 0;

our @rnews_command = qw(/usr/sbin/rnews);

sub new {
  my ($class) = @_;
  return bless { rnews_command => [ @rnews_command ] }, $class;
}

sub open {
  my ($self) = @_;
  if ($self->{'out'}) { return; }
  $self->check_perms;

  CORE::open my $out, '|-', @{$self->{'rnews_command'}}
    or croak "Cannot run ",_command_str($self),": $!";

  require Net::NNTP;
  my $hostname = 'localhost';
  my $nntp = Net::NNTP->new ($hostname, (DEBUG ? (Debug => 1) : ()))
    || croak "Cannot connect to '$hostname' nntp: $@";

  $self->{'out'} = $out;
  $self->{'nntp'} = $nntp;
}
sub _command_str {
  my ($self) = @_;
  return '\'' . join(' ', @{$self->{'rnews_command'}}) . '\'';
}

# Anonymous handle $self->{'out'} closes automatically on destruction, and
# $self->{'nntp'} will take care of its destruction.  Maybe should print
# some warnings on error though ...
#
# sub DESTROY {
#   my ($self) = @_;
# }

sub close {
  my ($self) = @_;
  $self->flush;
  if (my $nntp = delete $self->{'nntp'}) {
    $nntp->quit;
  }
}

sub check_perms {
  my ($self) = @_;
  if ($self->{'perms'}) { return; }

  CORE::open my $out, '|-', @{$self->{'rnews_command'}}
    or croak "Cannot run ",_command_str($self),": $!";
  CORE::close $out
    or croak "Error from ",_command_str($self),": ",($! || _exit_status_desc($?));
  $self->{'perms'} = 1;
}

sub nntp {
  my ($self) = @_;
  $self->open;
  return $self->{'nntp'};
}

sub write {
  my ($self, $msg) = @_;
  $self->open;
  if ($self->message_exists ($msg)) { return; }
  if (ref $msg) { $msg = $msg->as_string; }

  my $fh = $self->{'out'};
  print $fh "#! rnews ", length($msg), "\n", $msg
    or die "Error writing to rnews program: $!\n";
}
sub message_exists {
  my ($self, $msg) = @_;
  my $msgid;
  if (ref $msg) {
    $msgid = $msg->head->get('Message-ID');
    $msgid =~ s/\n$//;
  } else {
    if ($msg =~ /^Message-ID:\s*(<.*>)$/m) {
      $msgid = $1;
    }
  }
  return $self->message_id_exists ($msgid);
}
sub message_id_exists {
  my ($self, $msgid) = @_;
  my $nntp = $self->{'nntp'};
  my $ret = defined $nntp->nntpstat($msgid);
  if (DEBUG) { print "'$msgid' ", $ret ? "exists already\n" : "new\n"; }
  return $ret;
}

sub flush {
  my ($self) = @_;
  if (my $out = delete $self->{'out'}) {
    CORE::close $out
      or croak "Error from rnews program: ", ($! || _exit_status_desc($?)),"\n";
  }
}

sub write_and_flush {
  my ($self, $msg) = @_;
  $self->write ($msg);
  $self->flush;
}

# return a string describing the given or current $? exit status
sub _exit_status_desc {
  my ($status) = @_;
  if (@_ < 1) { $status = $?; }

  # WIFEXITED etc may not exist on non-posix
  require POSIX;
  if (eval { POSIX::WIFEXITED($status) }) {
    return "exit " . POSIX::WEXITSTATUS($status);
  }
  if (eval { POSIX::WIFSIGNALED($status) }) {
    return "signal " . POSIX::WTERMSIG($status);
  }
  if (eval { POSIX::WIFSTOPPED($status) }) {
    return "stopped " . POSIX::WSTOPSIG($status);
  }
  return sprintf 'status %#X', $status;
}


1;
__END__

=head1 NAME

News::Rnews - write to news spool using rnews program

=for test_synopsis my ($message)

=head1 SYNOPSIS

 my $rnews = News::Rnews->new;
 $rnews->write ($message);

=head1 DESCRIPTION

B<!!! This is of pretty doubtful value.  Unless you really want to use the
leafnode rnews program you're better off with an nntp IHAVE or POST.>

C<News::Rnews> runs the C<rnews> program and writes given news messages to
it.  An NNTP connection is made to the news server too, to suppress messages
already in the spool by C<Message-ID>.

This module has been written for Leafnode version 2, but might perhaps one
day work with INN or Cnews too.

=head1 FUNCTIONS

=head2 Message Handling

=over 4

=item C<< $rnews = News::Rnews->new >>

Create and return an Rnews object.

=item C<< $rnews->open >>

Start the C<rnews> subprocess and NNTP connection.  This is done
automatically by the first C<write> (below), so you don't have to do it
explicitly except to be sure in advance of having the necessary connection
and permissions.

=item C<< $rnews->write ($message) >>

Write the given C<$message> to C<rnews>.  If it already exists in the spool
then it's silently discarded.

C<$message> can be a string of bytes which is the message, or a
C<MIME::Entity> or C<MIME::Lite> object.

When building a message or gatewaying from mail note that a C<Path> header
is mandatory, even if it's just some dummy hostname.

=item C<< $rnews->flush ($message) >>

Write any queued messages to the spool now.  This means sending EOF to the
C<rnews> subprocess and checking it finishes successfully.

A new subprocess will be started automatically on the next C<write>.  But
note that starting a new subprocess for a flush like this can be a bit slow
if your groupinfo file is big.

=item C<< $rnews->close >>

Flush messages queued to the C<rnews> program (as per C<flush>), and close
the NNTP connection too.  This is done automatically when the C<$rnews>
object is destroyed (garbage collected) but doing it explicitly lets you be
sure it's successful.

=back

=head2 Other Funcs

=over 4

=item C<< $rnews->message_exists ($message) >>

=item C<< $rnews->message_id_exists ($msgid) >>

Return true if the given message is already in the spool.

C<message_exists> takes a whole message as a byte string, C<MIME::Entity> or
C<MIME::Lite> per C<write> above and its C<Message-ID> header is used.
C<message_id_exists> takes just the message ID string, without any C<E<lt>>
or C<E<gt>> brackets.

Although C<write> automatically discards duplicates, you might want to check
for a duplicate before doing the work of downloading or building a message.
C<message_id_exists> lets you do that conveniently.

=item C<< $rnews->check_perms >>

Check that the C<rnews> program can be successfully run, which usually means
having user C<news> permissions, and die if not.

This is done automatically at the first C<< write >> or C<< open >> (and
then remembered if ok) but can be called explicitly to check earlier.

=back

=head1 SEE ALSO

L<Net::NNTP>, L<rss2leafnode>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/rss2leafnode/index.html>

=head1 LICENSE

Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015 Kevin Ryde

RSS2Leafnode is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

RSS2Leafnode is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
RSS2Leafnode.  If not, see L<http://www.gnu.org/licenses/>.

=cut
