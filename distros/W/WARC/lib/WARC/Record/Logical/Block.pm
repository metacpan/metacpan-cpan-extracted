package WARC::Record::Logical::Block;				# -*- CPerl -*-

use strict;
use warnings;

our @ISA = qw();

use WARC; *WARC::Record::Logical::Block::VERSION = \$WARC::VERSION;

use Carp;
use Fcntl qw/SEEK_SET SEEK_CUR SEEK_END/;

# This implementation uses an array as the underlying object.

use constant { PARENT => 0, SEGMENT => 1, HANDLE => 2 };
use constant OBJECT_INIT => undef, 0, undef;

# Invariant:  HANDLE is always valid if SEGMENT is within range.

BEGIN { require WARC::Record::Logical; }
BEGIN { $WARC::Record::Logical::Block::{$_} = $WARC::Record::Logical::{$_}
	  for WARC::Record::Logical::SEGMENT_INDEX; }

sub _dbg_dump {
  my $self = shift;

  my $out = 'logical record block';
  $out .= ' @['.($self->[SEGMENT]).' / '
    .($#{$self->[PARENT]{segments}}).']';
  $out .= ' [EOF]' if $self->[SEGMENT] > $#{$self->[PARENT]{segments}};
  $out .= "\n";
  $out .= ' '.((tied *{$self->[HANDLE]})->_dbg_dump)
    if $self->[HANDLE] && UNIVERSAL::can(tied *{$self->[HANDLE]}, '_dbg_dump');

  return $out;
}

sub TIEHANDLE {
  my $class = shift;
  my $parent = shift;

  my $ob = [OBJECT_INIT];
  $ob->[PARENT] = $parent;
  $ob->[HANDLE] = $parent->{segments}[0][SEG_REC]->open_block;

  bless $ob, $class;
}

# advance to next segment; return false if already at last segment
sub _next_segment {
  my $self = shift;

  unless ($self->[PARENT]{segments}[1+$self->[SEGMENT]])
    { $self->[SEGMENT]++; return 0 }

  close $self->[HANDLE];
  $self->[HANDLE] =
    $self->[PARENT]{segments}[++$self->[SEGMENT]][SEG_REC]->open_block;
  return $self->[HANDLE];
}

sub READLINE {
  my $self = shift;

  if (wantarray) {	# data slurp; we might run out of memory...
    my @data = ();
    while (defined(my $line = $self->READLINE())) { push @data, $line }
    return @data
  }

  return undef if $self->[SEGMENT] > $#{$self->[PARENT]{segments}};

  if (not defined $/) {	# file slurp; we might run out of memory...
    my $data = readline $self->[HANDLE];
    $data = '' unless defined $data;
    $data .= readline $self->[HANDLE] while $self->_next_segment;
    return (length($data) ? $data : undef);
  } elsif (ref $/) {	# record read; fill a block...
    use bytes;
    my $rec_len = 0+${$/};
    my $rec = readline $self->[HANDLE];
    $rec = '' unless defined $rec;
    while (length $rec < $rec_len) {
      local $/ = \(do {$rec_len - length $rec});
      last unless $self->_next_segment;
      $rec .= readline $self->[HANDLE];
    }
    return (length ($rec) ? $rec : undef);
  } elsif ($/ eq '') {	# paragraph read; delimiter is empty line...
    my $para = '';
    my $input = readline $self->[HANDLE];

    while (((defined $input and $para .= $input) or $self->_next_segment)
	   and ("\n\n" ne substr $para, -2))
      # segment boundary was in the middle of a line, continuing read is safe
      { $input = readline $self->[HANDLE] }
    # paragraph delimiter may or may not span segments...
    if (eof $self->[HANDLE]) {
      # next segment may begin with newlines, if so, they must be read
      my $ch; my $end_pos = $self->TELL;
      $end_pos = $self->TELL, $para .= "\n"
	while (defined ($ch = $self->GETC) and $ch eq "\n");
      $self->SEEK($end_pos, SEEK_SET);
      $input = defined($ch) ? '' : undef;
    }
    return (length ($para) ? $para : undef);
  } else {		# ordinary line read...
    use bytes;	# a line delimiter may be split on any octet boundary
    my $line = '';
    my $input = readline $self->[HANDLE];

    # read more data until we have a complete line or reach EOF
    while (((defined $input and $line .= $input) or $self->_next_segment)
	   and ($/ ne substr $line, -length $/)) {
      if (length $/ > 1) {
	# each number N in this array indicates that a length-N prefix of
	# $/ currently matches at the end of the line buffer
	my @prefixes =
	  grep {substr($/, 0, $_) eq substr($line, -$_)} 1 .. length $/;
	while (@prefixes) {
	  my $count = $self->READ($input, 1);
	  return $line unless $count;
	  $line .= $input;
	  return $line if $/ eq substr $line, -length $/;
	  unshift @prefixes, 0; @prefixes = # sieve prefixes
	    grep {++$_; substr($/, 0, $_) eq substr($line, -$_)} @prefixes;
	}   # loop iterates until no prefix of $/ matches the tail of $line
      }

      $input = readline $self->[HANDLE];
    }
    return $input unless length $line;
    return $line;
  }
}

# This sub must rely on the aliasing effect of @_.
sub READ {
  my $self = shift;
  # args now:  0: buffer  1: length  2: offset into buffer or undef
  my $length = $_[1];
  my $offset = $_[2] || 0;

  return 0 if $self->[SEGMENT] > $#{$self->[PARENT]{segments}};

  my $buf = ''; my $count = 1; my $bpos = 0;
  while ($length && ($count || $self->_next_segment)) {
    $count = read $self->[HANDLE], $buf, $length, $bpos;
    return undef unless defined $count;
    $length -= $count; $bpos += $count;
  }

  $_[0] = '' unless defined $_[0];
  $_[0] .= "\0" x ($offset - length($_[0])) if $offset > length $_[0];
  substr $_[0], $offset, (length($_[0]) - $offset), $buf;
  return $bpos;
}

sub GETC {
  my $self = shift;

  my $ch;
  return undef unless $self->READ($ch, 1);
  return $ch;
}

sub EOF {
  my $self = shift;

  return 1 if $self->[SEGMENT] > $#{$self->[PARENT]{segments}};
  return 0 if $self->[SEGMENT] < $#{$self->[PARENT]{segments}};
  return eof $self->[HANDLE];
}

sub SEEK {
  my $self = shift;
  my $offset = shift;
  my $whence = shift;

  my $segments = $self->[PARENT]{segments};

  my $npos;

  if    ($whence == SEEK_SET)	{ $npos = $offset }
  elsif ($whence == SEEK_CUR)	{ $npos = $self->TELL + $offset }
  elsif ($whence == SEEK_END)
    { $npos = ($segments->[-1][SEG_BASE]
	       + $segments->[-1][SEG_LENGTH] + $offset) }
  else { croak "unknown WHENCE $whence in call to seek" }

  # This function must be able to seek backwards, even if the underlying
  # handles cannot, to support paragraph reads.  Seeking generally requires
  # finding the new segment, switching to that segment, and seeking
  # forwards to the desired offset within the new segment.

  # Special handling for seek to or past end-of-file
  if ($npos >= ($segments->[-1][SEG_BASE] + $segments->[-1][SEG_LENGTH])) {
    $self->[SEGMENT] = @$segments;
    close $self->[HANDLE]; $self->[HANDLE] = undef;
    return 1;
  }

  my $new_segment_index = @$segments;
  for (my $i = 0; $i < $new_segment_index; $i++) {
    $new_segment_index = $i	# which also exits this loop
      if $npos >= $segments->[$i][SEG_BASE]
	&& $npos < ($segments->[$i][SEG_BASE] + $segments->[$i][SEG_LENGTH]);
  }

  my $new_segment = $segments->[$new_segment_index];
  return 0 unless $new_segment;

  $self->[SEGMENT] = $new_segment_index;
  close $self->[HANDLE];
  $self->[HANDLE] = $new_segment->[SEG_REC]->open_block;
  seek $self->[HANDLE], $npos - $new_segment->[SEG_BASE], SEEK_SET;
}

sub TELL {
  my $self = shift;

  my $segments = $self->[PARENT]{segments};

  return ($segments->[$self->[SEGMENT]][SEG_BASE] + (tell $self->[HANDLE]))
    if $self->[SEGMENT] <= $#{$segments};
  return ($segments->[-1][SEG_BASE] + $segments->[-1][SEG_LENGTH]);
}

sub CLOSE {
  my $self = shift;
  $self->[SEGMENT] = 1+$#{$self->[PARENT]{segments}};
  close $self->[HANDLE]; $self->[HANDLE] = undef;
}

1;
__END__

=head1 NAME

WARC::Record::Logical::Block - reassemble data block from continued record

=head1 SYNOPSIS

  use WARC::Record;

=head1 DESCRIPTION

This is an internal class used to implement the C<open_block> instance
method on C<WARC::Record::Logical> objects and the C<open_continued>
instance method on C<WARC::Record> objects.  This class provides tied
filehandles and the methods are documented in L<perltie/"Tying
FileHandles"> and L<perlfunc>.

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC::Record>
L<perltie/"Tying FileHandles">
L<perlfunc>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
