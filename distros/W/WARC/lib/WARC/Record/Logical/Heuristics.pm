package WARC::Record::Logical::Heuristics;			# -*- CPerl -*-

use strict;
use warnings;

our @ISA = qw();

use WARC; *WARC::Record::Logical::Heuristics::VERSION = \$WARC::VERSION;

use Carp;
use File::Spec;

=head1 NAME

WARC::Record::Logical::Heuristics - heuristics for locating record segments

=head1 SYNOPSIS

  use WARC::Record::Logical::Heuristics;

=head1 DESCRIPTION

This is an internal module that provides functions for locating record
segments when the needed information is not available from an index.

These mostly assume that IIPC WARC guidelines have been followed, as
otherwise there simply is no efficient solution.

Implementations vary, however, with some using only an incrementing serial
number and a constant timestamp from the initiation of the crawl job, while
the guidelines and specification envision a timestamp reflecting the first
write to that specific file rather than the start of the crawl.  Constant
timestamps are checked first, since the search is simpler.

=over

=item $WARC::Record::Logical::Heuristics::Patience

This variable sets a threshold used to limit the reach of an unproductive
search.  This module tracks the "effort" expended (I/O performed) during a
search and abandons the search if the threshold is exceeded.  Finding
results dynamically (and temporarily) increases this threshold during a
search, such that this really sets how far the search will go between
results before giving up and concluding that there are no more results.

The search will reach farther if either the WARC files are not compressed,
or the "sl" GZIP extension documented in L<WARC::Builder> is used.
Decompressing record data to find the next record is considerable effort
for larger records, but is not counted for very small records that the
system is likely to already have cached after the header has been read.

=cut

# These provide a simple mechanism to limit the scope of a search that is
# not producing results.  Both are localized in the top-level calls.

our $Patience = 10000;	# How much effort to put into a search?
our $Effort = 0;	# How much have we done so far during this search?

# Most I/O incurs "effort", represented by incrementing $Effort, while
# partial success (finding an interesting record) increases "patience",
# represented by incrementing $Patience.  The search stops when either
# there are no more places to look or $Effort exceeds $Patience.

=item %WARC::Record::Logical::Heuristics::Effort

This internal hash indicates how costly certain operations should be
considered.  The keys and their meanings are subject to change at whim, but
this is available for quick tuning if needed.  Generally, the better
solution is to index your data rather than spend time tuning heuristics.

=cut

our %Effort =
  (# read_record:
   #  effort incurred to read a record header, regardless of compression
   read_record => 5,

   # gzread_data_per_tick:
   #  number of bytes to read while advancing past a compressed record to
   #  incur one effort point; effort incurred rounds down, even to zero
   #
   #  this value is a shot-in-the-dark estimate that gunzipping 320 KiB is
   #  equivalent to the open/seek/read process for loading a record header
   gzread_data_per_tick => 64 * 1024,

   # readdir_files_per_tick:
   #  number of file names to read and check while scanning a directory for
   #  to incur one effort point; effort incurred rounds down, even to zero
   #
   #  this value is a shot-in-the-dark estimate that reading/matching 1600
   #  file names is equivalent to loading a record header; this estimate
   #  may be high or low depending on the number of axes used in the search
   readdir_files_per_tick => 320,
  );

# Internal functions:

## @axes = _split_digit_spans( $filename )
##
##  Extract possible sequence numbers from $filename and return list of
##  array references [PREFIX, NUMBER, SUFFIX] where NUMBER is a field that
##  can be adjusted to find "nearby" files if NUMBER turns out to actually
##  be a sequence number.  Finds numerous false matches in normal use, but
##  broad searches cost only time while excessive narrowing causes failure.
##
##  Does not perform I/O; does not increment $Effort.

sub _split_digit_spans ($) {
  my $name = shift;
  my @axes = ();

  # Split on zero-width boundaries between digits and non-digits.
  my @pieces = split /(?=[0-9])(?<=[^0-9])|(?=[^0-9])(?<=[0-9])/, $name;
  # The @pieces array now contains alternating spans of digits and non-digits.

  for (my $i = 0; $i < @pieces; $i++) {
    next unless ($pieces[$i] =~ /^[0-9]+$/ && length($pieces[$i]) < 9);
    # More than 8 digits is probably not a sequence number and may be
    # beyond the range of an integer anyway.  Use indexes instead of
    # heuristics if you need to work with a billion WARC files.
    push @axes, [join('', @pieces[0..($i-1)]),
		 $pieces[$i], join('', @pieces[($i+1)..$#pieces])];
  }

  return @axes;
}

## @found = _find_nearby_files( $direction, @axes )
##
##  Locate existing files that appear to be part of a contiguous sequence
##  along an axis in @axes.  The $direction argument is either +1 to search
##  for higher numbers or -1 to search for lower numbers.  A direction
##  value with a magnitude greater than 1 results in skipping possibilities
##  during the search.
##
##  Returns a list of array references reflecting the files along each axis
##  from the argument list but omitting axes on which no files were found.
##
##  Performs only directory lookups, which have highly unpredictable costs
##  and are usually cached by the system; does not increment $Effort.

sub _find_nearby_files ($@) {
  my $direction = shift;
  my @found = ();

  foreach my $axis (@_) {
    my @files = ();
    my $i = $axis->[1] + $direction; my $file;
    while (-f ($file = join '', ($axis->[0],
				 sprintf('%0*d', length $axis->[1], $i),
				 $axis->[2])))
      { push @files, $file; $i += $direction }
    push @found, \@files if scalar @files;
  }

  return @found;
}

## @found = _scan_directory_for_axes( $dirname, @axes )
##
##  Locate existing files that may appear to be part of a sequence along an
##  axis in @axes, using wildcards for long digit spans.
##
##  The $dirname argument specifies the name of a directory to search and
##  all @axes are interpreted relative to $dirname.  This differs from
##  _find_nearby_files where each axis specifies full absolute filenames.
##  For this function, the axes are strictly filenames with no directory.
##
##  Returns a list of array references reflecting the files along each axis
##  from the argument list but omitting axes on which no files were found.
##
##  Performs directory reads; increments $Effort to count file names read.

sub _scan_directory_for_axes ($@) {
  my $dirname = shift;
  my $read_count = 0;

  my @re = map {
    my $pre = quotemeta $_->[0]; my $post = quotemeta $_->[2];
    $pre  =~ s/(?<=[^0-9])([0-9]{9,})(?=[^0-9])/'[0-9]{'.(length $1).'}'/eg;
    $post =~ s/(?<=[^0-9])([0-9]{9,})(?=[^0-9])/'[0-9]{'.(length $1).'}'/eg;
    my $midlen = length $_->[1]; qr/^$pre[0-9]{$midlen}$post/ } @_;

  my $filename;
  my @found = ();
  opendir my $dir, $dirname or croak "$dirname: $!";
  while (defined ($filename = readdir $dir)) {
    foreach (0 .. $#re) {
      if ($filename =~ $re[$_])
	{ push @{$found[$_]}, $filename }
    }
    $read_count++;
  }
  closedir $dir;

  $Effort += int($read_count / $Effort{readdir_files_per_tick});
  return grep {scalar @$_} @found;
}

## @similar = _find_similar_files( $seed )
##
## Locate existing files that may appear to be part of a sequence involving
## any digit span in $seed, using wildcards for long digit spans and
## searching only the directory containing $seed.
##
## Returns a list of array references, each containing two array references
## for files sorting before and after $seed, reflecting the files along
## each axis derived from $seed on which files other than $seed were found.
##
## Uses _scan_directory_for_axes; does not perform I/O directly.

sub _find_similar_files ($) {
  my $seedfile = shift;

  my $fs_volname; my $dirname; my $filename;
  ($fs_volname, $dirname, $filename) = File::Spec->splitpath($seedfile);

  my @found = _scan_directory_for_axes
    (File::Spec->catpath($fs_volname, $dirname, ''),
     _split_digit_spans $filename);
  my @similar = ();
  foreach my $axis_files (@found) {
    my @before = (); my @after = ();
    foreach my $fname (@$axis_files) {
      if ($fname lt $filename) {
	push @before, File::Spec->catpath($fs_volname, $dirname, $fname);
      } elsif ($fname gt $filename) {
	push @after,  File::Spec->catpath($fs_volname, $dirname, $fname);
      }
    }
    push @similar, [[sort {$a cmp $b} @before],
		    [sort {$a cmp $b} @after]] if @before + @after;
  }

  return @similar;
}

## ($checkpoint, @records) =
##	_scan_volume( $volume, $start, $end, [$field, $value]... )
##
##  Search $volume for segment records where any $field matches $value
##  starting at offset $start and ending at or after offset $end.  If $end
##  is an undefined value, searches until end-of-file.
##
##  Only returns records that have a 'WARC-Segment-Number' header.
##
##  The returned $checkpoint is the last record examined, regardless of
##  header values, and provides a valid offset for resuming a search.

sub _scan_volume ($$$@) {
  my $volume = shift;
  my $start = shift;
  my $end = shift;

  my $record = $volume->record_at($start);
  my @records = ();

  while ($record && (!defined $end || $record->offset <= $end)) {
    $Effort += $Effort{read_record};
    next unless (defined $record->field('WARC-Segment-Number')
		 && grep {defined $record->field($_->[0])} @_);
    push @records, $record if grep {defined $record->field($_->[0])
				      && $record->field($_->[0]) eq $_->[1]} @_;
  } continue { $Effort += int($record->field('Content-Length')
			      / $Effort{gzread_data_per_tick})
		 if (defined $record->{compression}
		     && !defined $record->{sl_packed_size});
	       $record = $record->next }

  return $record, @records;
}

=item ( $first_segment, @clues ) = find_first_segment( $record )

Attempt to locate the first segment of the logical record suggested by the
given record without using indexes.  Croaks if given a record that does not
appear to have been written using WARC segmentation.  Returns a
C<WARC::Record> object for the first record and a list of other objects
that may be useful for locating continuation records.  Returns undef in the
first slot if no clear first segment was found, but can still return other
records encountered during the search even if the search was ultimately
unsuccessful.

=cut

## Each "clue" can be a WARC::Record, or a hint in the form of [key => value].
##
## The hint keys currently are:
##
##	tail		=>	$record
##		last record examined in initial volume
##		(a good starting point to search for more segments)
##
##	files_on_axes	=>	[$filename, ...]...
##		array of arrays from _find_nearby_files
##	files_from_dir	=>	[[$filename...], [$filename...]]...
##		array of arrays from _find_similar_files
##	Note that the filenames are set to undef in these hints as the
##	corresponding WARC volumes are scanned, with any relevant records
##	added directly to the clue list as they are found.

sub find_first_segment {
  local $Patience = $Patience;
  local $Effort = 0;

  my $initial = shift;

  croak 'searching for segments for unsegmented record'
    unless defined $initial->field('WARC-Segment-Number');

  my $origin_id = $initial->field('WARC-Segment-Origin-ID');
  my @clues = (); my $point; my @records;

  # First we search the volume containing the initial record, since
  # multiple WARC files may have been concatenated together after writing.
  ($point, @records) = _scan_volume $initial->volume, 0, $initial->offset,
    [WARC_Segment_Origin_ID => $origin_id], [WARC_Record_ID => $origin_id];
  # ... @records will always include $initial ...
  push @clues, @records, [tail => $point];

  foreach my $record (@records) {
    return $record, @clues if $record->field('WARC-Record-ID') eq $origin_id;
  }
  $Patience += $Effort * ((scalar @records) - 1);
  return undef, @clues if $Effort > $Patience;

  # If we get this far, the first segment must be in another volume.
  {
    my @simple_axes = _split_digit_spans $initial->volume->filename;
    my @nearby = _find_nearby_files -1, @simple_axes;

    # A simple sequence number may be in use; we can check these volumes
    # before reading the directory to handle varying timestamps.
    push @clues, [files_on_axes => @nearby] if scalar @nearby;
    foreach my $axis_files (reverse @nearby) {
      # Work backwards on the assumption that sequence numbers are nearer
      # to the end of the filename.  (Correct for Wget and Wpull.)
      foreach my $name (@$axis_files) {
	my $previousEffort = $Effort;
	my $volume = mount WARC::Volume ($name);
	(undef, @records) = _scan_volume $volume, 0, undef,
	  [WARC_Segment_Origin_ID => $origin_id],
	    [WARC_Record_ID => $origin_id];
	push @clues, @records; $name = undef;
	foreach my $record (@records) {
	  return $record, @clues
	    if $record->field('WARC-Record-ID') eq $origin_id;
	}
	$Patience += ($Effort - $previousEffort) * scalar @records;
	return undef, @clues if $Effort > $Patience;
      }
    }
  }

  # If we get this far, the first segment is in another volume and multiple
  # numbers must change to find that other volume.  Assume that timestamps
  # are in use in the file names, confounding the simple sequence search.
  {
    my @nearby = _find_similar_files $initial->volume->filename;

    push @clues, [files_from_dir => @nearby] if scalar @nearby;
    # Work forwards on the assumption that sequence numbers are nearer to
    # the beginning of the filename.  (Correct in Internet Archive samples.)
    foreach my $fname ((map {reverse @{$_->[0]}} @nearby),
		       # work backwards within the "before" list on each axis
		       # ... and forwards within the "after" list on each axis
		       (map {@{$_->[1]}} @nearby)) {
      my $previousEffort = $Effort;
      my $volume = mount WARC::Volume ($fname);
      (undef, @records) = _scan_volume $volume, 0, undef,
	[WARC_Segment_Origin_ID => $origin_id],
	  [WARC_Record_ID => $origin_id];
      push @clues, @records; $fname = undef;
      foreach my $record (@records) {
	return $record, @clues
	  if $record->field('WARC-Record-ID') eq $origin_id;
      }
      $Patience += ($Effort - $previousEffort) * scalar @records;
      return undef, @clues if $Effort > $Patience;
    }
  }

  # If we get this far, we have run out of places to look and the user will
  # need to build an index instead of relying on heuristics.
  return undef, @clues;
}

=item ( @segments ) = find_continuation( $first_segment, @clues )

Attempt to locate the continuation segments of a logical record without
using indexes.  Uses the clues returned from C<find_first_segment> to aid
in the search and returns a list of continuation records found that appear
to be part of the same logical record as the given first segment.

=cut

sub _add_segments (\$\@\@) {
  my $total_segment_count_ref = shift;
  my $have_segments_ref = shift;
  my $new_segments_ref = shift;

  foreach (@$new_segments_ref) {
    $have_segments_ref->[$_->field('WARC-Segment-Number')]++;
    $$total_segment_count_ref = $_->field('WARC-Segment-Number')
      if defined $_->field('WARC-Segment-Total-Length');
  }
}
sub _have_all_segments_p ($@) {
  my $total_segment_count = shift;

  # We cannot have all segments if we have not seen the last segment yet.
  return 0 unless defined $total_segment_count;

  # We have seen the last segment, do we have all of the others?
  for (my $i = 2; $i < $total_segment_count; $i++) { return 0 unless $_[$i] }
  #  Start the search at 2 because offsets 0 and 1 are not used here.

  return 1;
}

sub find_continuation {
  local $Patience = $Patience;
  local $Effort = 0;

  my $first_segment = shift; my $origin_id = $first_segment->id;

  # First we unpack the clues and check if all segments were found while
  # searching for the first segment.
  my @segments = (); my @nearby_volume_files = ();
  my $have_tail = 0; my $point = undef;
  my @similar_volume_files_before = (); my @similar_volume_files_after = ();
  foreach my $clue (@_) {
    if (UNIVERSAL::isa($clue, 'WARC::Record')) {
      push @segments, $clue unless $clue == $first_segment;
    } elsif (ref $clue eq 'ARRAY') {
      my $tag = shift @$clue;
      if ($tag eq 'tail') {
	$have_tail = 1;
	$point = shift @$clue;
      } elsif ($tag eq 'files_on_axes') {
	push @nearby_volume_files, map {[grep defined, @$_]} @$clue;
      } elsif ($tag eq 'files_from_dir') {
	foreach (@$clue) {
	  push @similar_volume_files_before, [grep defined, @{$_->[0]}];
	  push @similar_volume_files_after,  [grep defined, @{$_->[1]}];
	}
      } else { die "unrecognized hint tag: $tag" }
    } else { die "unrecognized clue" }
    $clue = undef;
  }
  @similar_volume_files_before = grep {scalar @$_} @similar_volume_files_before;
  @similar_volume_files_after  = grep {scalar @$_} @similar_volume_files_after;

  my @have_segments = (); my $total_segment_count = undef;
  _add_segments $total_segment_count, @have_segments, @segments;

  return @segments if _have_all_segments_p $total_segment_count, @have_segments;

  # If we get to here, at least one segment was not found while searching
  # for the first segment, so we will need to search too.
  my @records = ();

  # Pick up where find_first_segment left off...
  if ($point) {
    (undef, @records) = _scan_volume $point->volume, $point->offset, undef,
      [WARC_Segment_Origin_ID => $origin_id];
    _add_segments $total_segment_count, @have_segments, @records;
    push @segments, @records;
  } elsif (!$have_tail) {
    # The search may have begun with the first segment directly; ensure
    # that we scan the entire volume containing the first segment later.
    push @nearby_volume_files, [$first_segment->volume->filename];
  }
  $Patience += $Effort * scalar @records;
  return @segments
    if (_have_all_segments_p $total_segment_count, @have_segments
	or $Effort > $Patience);

  # Search for more volumes in a simple sequence...
  {
    my @simple_axes = _split_digit_spans $first_segment->volume->filename;
    my @nearby = _find_nearby_files 1, @simple_axes;

    # Were more volumes found in the simple sequence search now or previously?
    foreach my $axis_files ((reverse @nearby),
			    (reverse @nearby_volume_files)) {
      # Work backwards on the assumption that sequence numbers are nearer
      # to the end of the filename.  (Correct for Wget and Wpull.)
      foreach my $name (@$axis_files) {
	my $previousEffort = $Effort;
	my $volume = mount WARC::Volume ($name);
	(undef, @records) = _scan_volume $volume, 0, undef,
	  [WARC_Segment_Origin_ID => $origin_id];
	_add_segments $total_segment_count, @have_segments, @records;
	push @segments, @records;
	$Patience += ($Effort - $previousEffort) * scalar @records;
	return @segments
	  if (_have_all_segments_p $total_segment_count, @have_segments
	      or $Effort > $Patience);
      }
    }
  }

  # Search for more volumes by directory scan...
  {
    unless (@similar_volume_files_before + @similar_volume_files_after) {
      # Unlike the simple sequence search, the directory scan finds files
      # in both directions from the starting point on all axes, but it may
      # not have been needed to find the first segment.  Do it now if not.
      my @nearby = _find_similar_files $first_segment->volume->filename;
      foreach (@nearby) {
	push @similar_volume_files_before, $_->[0];
	push @similar_volume_files_after,  $_->[1];
      }
    }
    # Any interesting records in volumes before the volume containing the
    # initial record were probably found while locating the first segment.
    foreach my $axis_files (@similar_volume_files_after,
			    reverse @similar_volume_files_before) {
      # Work forwards on the assumption that sequence numbers are nearer to
      # the beginning of the filename.  (Correct in Internet Archive samples.)
      foreach my $fname (@$axis_files) {
	my $previousEffort = $Effort;
	my $volume = mount WARC::Volume ($fname);
	(undef, @records) = _scan_volume $volume, 0, undef,
	  [WARC_Segment_Origin_ID => $origin_id];
	_add_segments $total_segment_count, @have_segments, @records;
	push @segments, @records;
	$Patience += ($Effort - $previousEffort) * scalar @records;
	return @segments
	  if (_have_all_segments_p $total_segment_count, @have_segments
	      or $Effort > $Patience);
      }
    }
  }

  # If we get to here, we have run out of places to look and the user will
  # need to build an index instead of relying on heuristics.
  return @segments;
}

=back

=cut

1;
__END__

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC>, L<WARC::Collection>, L<WARC::Record>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
