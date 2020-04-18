package WARC::Record::FromVolume;				# -*- CPerl -*-

use strict;
use warnings;

our @ISA = qw(WARC::Record);
our @CARP_NOT = (@ISA, qw(WARC::Volume WARC::Record::Stub));

use WARC; *WARC::Record::FromVolume::VERSION = \$WARC::VERSION;

use Carp;
use Fcntl 'SEEK_SET';
use Symbol 'geniosym';
use IO::Uncompress::Gunzip '$GunzipError';

require WARC::Fields;
require WARC::Record;
require WARC::Record::Block;
require WARC::Record::Replay;

# The overload to a method call is inherited.
sub compareTo {
  my $a = shift;
  my $b = shift;
  my $swap = shift;

  # sort in-memory-only records ahead of on-disk records
  return $swap ? -1 : 1 unless defined $b->volume;

  my $cmp =
    ((($a->volume->filename eq $b->volume->filename)
      || ($a->volume->_file_tag eq $b->volume->_file_tag))
     ? ($a->offset <=> $b->offset)
     : ($a->volume->filename cmp $b->volume->filename));

  return $swap ? 0-$cmp : 0+$cmp;
}

# This implementation uses a hash as the underlying structure.

#  Keys inherited from WARC::Record base class:
#
#   fields

#  Keys defined by this class:
#
#   volume
#	Parent WARC::Volume object
#   collection (optional)
#	Parent WARC::Collection object, if record found via a collection
#   offset
#	Offset of start-of-record within parent volume
#   compression
#	Name of decompression filter used with this record
#   data_offset
#	Offset of data block within record (possibly compressed)
#   payload_offset (optional)
#	Offset of record payload within data block
#	  (Defined by this class, but only set upon protocol replay.)
#   payload_encodings (optional)
#	Array of transfer encodings, an undefined value, and content
#	 encodings for the payload data for this record.
#	  (Defined by this class, but only set upon protocol replay.)
#	  (NOT YET IMPLEMENTED)
#   sl_packed_size
#	Size of compressed data block according to "sl" gzip extension
#   sl_full_size
#	Size of uncompressed data block according to "sl" gzip extension
#   protocol
#	WARC version found at start of record
#   logical (optional)
#	Weak reference to logical record object containing this segment
#	  (Defined by this class, but only set by WARC::Record::Logical.)

#  Keys tested by logical record heuristics:
#
#   compression
#	defined iff record is compressed
#   sl_packed_size
#	defined iff compressed record can be skipped without reading data block

#  Keys used in index writers:
#
#   sl_packed_size
#	used for "S" field in CDX indexes

sub DESTROY { our $_total_destroyed;	$_total_destroyed++ }

sub _dbg_dump {
  my $self = shift;

  my $out = 'WARC '.$self->field('WARC-Type').' record ['.$self->protocol.']';
  $out .= ' [via '.$self->{compression}.']' if defined $self->{compression};
  $out .= "\n";

  $out .= ' id '.$self->id."\n";

  $out .= ' at '.$self->offset.' in '.$self->volume."\n";
  $out .= '  "sl" header:  '.$self->{sl_packed_size}.' packed from '
    .$self->{sl_full_size}." octets\n" if defined $self->{sl_full_size};

  $out .= ' data begins at offset '.$self->{data_offset};
  $out .= ' within '.(defined $self->{compression} ? 'record' : 'volume');
  $out .="\n";

  return $out;
}

sub _get_compression_error {
  my $self = shift;

  if (not defined $self->{compression}) {
    return '(record not compressed)';
  } elsif ($self->{compression} eq 'IO::Uncompress::Gunzip') {
    return $GunzipError;
  } else {
    die "unknown compression method";
  }
}

sub new { croak "WARC records are read from volumes" }

sub block {
  my $self = shift;

  croak "attempt to set block on record from volume" if @_;

  return undef;
}

sub _read {
  my $class = shift;
  my $volume = shift;
  my $offset = shift;

  croak "WARC::Record::FromVolume::_read is a class method"
    unless defined $class;
  croak "attempt to read WARC record from undefined volume"
    unless defined $volume;
  croak "attempt to read WARC record from undefined offset"
    unless defined $offset;

  my $handle;
  if (ref $offset) {		# I/O handle passed in instead
    $handle = $offset;
    $offset = tell $handle;
  } else {			# open new handle and seek to offset
    $handle = $volume->open;
    seek $handle, $offset, SEEK_SET or die "seek: $!";
  }

  my %ob = (volume => $volume, offset => $offset);

  my $magic; my $protocol = '';
  defined(read $handle, $magic, 6) or die "read: $!";
  return undef if $magic eq '';	# end-of-file reached

  if ($magic eq 'WARC/1') {
    # uncompressed WARC record found ==> pass it on through
    $protocol = $magic;
  } elsif (unpack('H4', $magic) eq '1f8b') {
    # gzip signature found ==> check for extension header and stack filter

    if (unpack('x3C', $magic) & 0x04) { # FLG.FEXTRA is set
      defined(read $handle, $magic, 6, 6) or die "read: $!";
      my $xlen = unpack 'v', substr $magic, -2;
      my $extra; defined(read $handle, $extra, $xlen) or die "read: $!";
      my @extra = unpack '(a2 v/a*)*', $extra;
      $magic .= $extra;
      # @extra is now (tag => $data)...
      for (my $i = 0; $i < @extra; $i += 2) {
	if ($extra[$i] eq 'sl' and length($extra[1+$i]) == 8)
	  { @ob{qw/sl_packed_size sl_full_size/} = unpack 'VV', $extra[1+$i] }
      }
    }

    $handle = new IO::Uncompress::Gunzip ($handle,
					  Prime => $magic, MultiStream => 0,
					  AutoClose => 1, Transparent => 0)
      or die "IO::Uncompress::Gunzip: $GunzipError";
    $ob{compression} = 'IO::Uncompress::Gunzip';
  } else
    { croak "WARC record header not found at offset $offset in $volume\n"
	." found [".join(' ', unpack '(H2)*', $magic)."] instead" }

  # read WARC version
  $protocol .= <$handle>;
  $protocol =~ s/[[:space:]]+$//;
  #  The WARC version read from the file is appended because an
  #   uncompressed WARC record is recognized by the first six bytes of the
  #   WARC version tag, which were transferred to $protocol if found.
  $protocol =~ m/^WARC/
    or croak "WARC record header not found after decompression\n"
      ." found [".join(' ', unpack '(H2)*', $protocol)."] instead";
  $ob{protocol} = $protocol;

  $ob{fields} = parse WARC::Fields from => $handle;
  $ob{fields}->set_readonly;

  $ob{data_offset} = tell $handle;

  close $handle;

  { our $_total_read;	$_total_read++ }

  bless \%ob, $class;
}

sub protocol { (shift)->{protocol} }

sub volume { (shift)->{volume} }

sub offset { (shift)->{offset} }

sub logical {
  my $self = shift;

  my $segment_header_value = $self->field('WARC-Segment-Number');
  if (defined $self->{logical}) {
    return $self->{logical};	# cached object remains valid ==> return it
  } elsif (defined $segment_header_value) {
    return _read WARC::Record::Logical $self;
  } else {
    return $self;		# no continuation records present
  }
}

sub segments { if (wantarray) { return shift } else { return 1 } }

sub next {
  my $self = shift;

  my $next = undef;

  if ($self->{sl_packed_size}) { # gzip "sl" extended header available
    my $handle = $self->volume->open;

    # seek to read 32-bit ISIZE field at end of gzip stream
    seek $handle, $self->offset + $self->{sl_packed_size} - 4, SEEK_SET
      or die "seek: $!";
    my $isize; defined(read $handle, $isize, 4) or die "read: $!";

    if (length $isize > 0	# read off the end yields nothing
	and $self->{sl_full_size} == unpack 'V', $isize) { # ... and looks valid
      $next = _read WARC::Record::FromVolume $self->volume, $handle;
      close $handle;
      return $next;
    } else {
      carp "extended 'sl' header was found to be invalid\n"
	.'  in record at '.($self->offset).' in '.($self->volume);
    }
  } elsif (not defined $self->{compression}) { # WARC record is not compressed
    return _read WARC::Record::FromVolume $self->volume,
      $self->{data_offset} + $self->field('Content-Length') + 4;
  }

  # if we get here, we have to scan for the end of the record
  my $handle = $self->volume->open;
  seek $handle, $self->offset, SEEK_SET or die "seek: $!";

  my $zhandle = $self->{compression}->new
    ($handle, MultiStream => 0, AutoClose => 0)
      or die "$self->{compression}: ".$self->_get_compression_error;
  seek $zhandle, $self->{data_offset} + $self->field('Content-Length'), SEEK_SET
    or die "zseek: $! ".$self->_get_compression_error;
  my $end; defined(read $zhandle, $end, 4)
    or die "zread: $! ".$self->_get_compression_error;
  croak "end-of-record marker not found" unless $end eq (WARC::CRLF x 2);

  # The main handle is somewhere *after* the actual end of the block
  #  because IO::Uncompress::Gunzip reads ahead.  We can get the contents
  #  of that "read ahead" buffer and use that to adjust our final offset.
  $next = _read WARC::Record::FromVolume $self->volume,
    (tell($handle) - length($zhandle->trailingData));

  close $zhandle; close $handle;

  return $next;
}

sub open_block {
  my $self = shift;

  my $xhandle = Symbol::geniosym;
  tie *$xhandle, 'WARC::Record::Block', $self;

  return $xhandle;
}

sub open_continued { (shift)->logical->open_block }

sub replay {
  my $self = shift;

  my @handlers = WARC::Record::Replay::find_handlers($self);

  my $result = undef;
  $result = (shift @handlers)->($self)
    while scalar @handlers && !defined $result;

  return $result;
}

sub open_payload {
  my $self = shift;

  my $replay = $self->replay;
  return undef unless $replay;	# no payload found

  my $xhandle = Symbol::geniosym;
  tie *$xhandle, 'WARC::Record::Payload', $self, $replay;

  return $xhandle;
}

1;
__END__

=head1 NAME

WARC::Record::FromVolume - WARC record from a WARC file

=head1 SYNOPSIS

  use WARC::Record;

=head1 DESCRIPTION

This is an internal class used to implement C<WARC::Record> objects
representing records in WARC files.  Methods in this class are documented
as part of C<WARC::Record>.

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC::Record>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019, 2020 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
