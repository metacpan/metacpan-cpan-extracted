=head1 NAME

Text::Same::Match

=head1 DESCRIPTION

Objects of this class represent a match between a group of chunks
(generally lines) in one source (eg a file) and a group of chunks in
another.  The "chunks" could potentially be paragraphs or sentences.

=head1 SYNOPSIS

 my @pairs = ($chunk_pair1, $chunk_pair2, ...);
 my $match = new Text::Same::Match(@pairs);

=head1 METHODS

See below.  Methods private to this module are prefixed by an
underscore.

=cut

package Text::Same::Match;

use warnings;
use strict;
use Carp;

use vars qw($VERSION);
$VERSION = '0.07';

=head2 new

 Title   : new
 Usage   : $match = new Text::Same::Match(@pairs)
 Function: Creates a new Match object from an array of ChunkPair objects
 Returns : A Text::Same::Match object
 Args    : an array of ChunkPair objects

=cut

sub new
{
  my $arg  = shift;
  my $class = ref($arg) || $arg;

  my $self = {@_};

  $self->{min1} = 999999999999;
  $self->{max1} = -1;
  $self->{min2} = 999999999999;
  $self->{max2} = -1;

  bless $self, $class;
  $self->_update_stats(@{$self->{pairs}});

  return $self;
}


=head2 add

 Title   : add
 Usage   : $match->add(@chunk_pairs);
 Function: add ChunkPair objects to this objects - no checks are made that
           the new ChunkPairs are ajacent to the current pairs
 Returns : $self
 Args    : an array of ChunkPair objects

=cut

sub add
{
  my $self = shift;
  $self->_update_stats(@_);
  push @{$self->{pairs}}, @_;
  $self;
}

=head2 source1

 Title   : source1
 Usage   : my $chunked_source = $match->source1;
 Function: get the ChunkedSource for the source 1
 Returns : a ChunkedSource reference
 Args    : none

=cut

sub source1
{
  my $self = shift;
  return $self->{source1};
}

=head2 source2

 Title   : source2
 Usage   : my $chunked_source = $match->source2;
 Function: get the ChunkedSource for the source 2
 Returns : a ChunkedSource reference
 Args    : none

=cut

sub source2
{
  my $self = shift;
  return $self->{source2};
}

sub _update_stats
{
  my $self = shift;
  my @new_pairs = @_;

  for my $chunk_pair (@new_pairs) {
    my $chunk_index1 = $chunk_pair->chunk_index1;
    my $chunk_index2 = $chunk_pair->chunk_index2;

    if ($chunk_index1 < $self->{min1}) {
      $self->{min1} = $chunk_index1;
    }
    if ($chunk_index1 > $self->{max1}) {
      $self->{max1} = $chunk_index1;
    }
    if ($chunk_index2 < $self->{min2}) {
      $self->{min2} = $chunk_index2;
    }
    if ($chunk_index2 > $self->{max2}) {
      $self->{max2} = $chunk_index2;
    }
  }
}


=head2 min1

 Title   : min1
 Usage   : $match->min1;
 Function: return the minimum index of the chunks in the first (ie. left) of
           the ChunkedSources held in this Match
 Args    : None

=cut

sub min1
{
  return $_[0]->{min1};
}

=head2 max1

 Title   : max1
 Usage   : $match->max1;
 Function: return the maximum index of the chunks in the first (ie. left) of
           the ChunkedSources held in this Match
 Args    : None

=cut

sub max1
{
  return $_[0]->{max1};
}

=head2 min2

 Title   : min2
 Usage   : $match->min2;
 Function: return the minimum index of the chunks in the second (ie. right) of
           the ChunkedSources held in this Match
 Args    : None

=cut

sub min2
{
  return $_[0]->{min2};
}

=head2 max2

 Title   : max2
 Usage   : $match->max2;
 Function: return the maximum index of the chunks in the second (ie. right) of
           the ChunkedSources held in this Match
 Args    : None

=cut

sub max2
{
  return $_[0]->{max2};
}

=head2 set_min1

 Title   : set_min1
 Usage   : $match->set_min1;
 Function: Set the minimum index of the chunks in the first (ie. left) of
           the ChunkedSources held in this Match

=cut

sub set_min1
{
  my $self = shift;
  my $new_val = shift;
  if ($new_val > $self->{max1}) {
    die "min greater than max\n";
  }
  $self->{min1} = $new_val;
}

=head2 set_min2

 Title   : set_min2
 Usage   : $match->set_min2;
 Function: Set the minimum index of the chunks in the second (ie. right) of
           the ChunkedSources held in this Match

=cut

sub set_min2
{
  my $self = shift;
  my $new_val = shift;
  if ($new_val > $self->{max2}) {
    die "min greater than max\n";
  }
  $self->{min2} = $new_val;
}

=head2 set_max1

 Title   : set_max1
 Usage   : $match->set_max1;
 Function: Set the maximum index of the chunks in the first (ie. left) of
           the ChunkedSources held in this Match

=cut

sub set_max1
{
  my $self = shift;
  my $new_val = shift;
  if ($new_val < $self->{min1}) {
    die "min greater than max\n";
  }
  $self->{max1} = $new_val;
}

=head2 set_max2

 Title   : set_max2
 Usage   : $match->set_max2;
 Function: Set the maximum index of the chunks in the second (ie. right) of
           the ChunkedSources held in this Match

=cut

sub set_max2
{
  my $self = shift;
  my $new_val = shift;
  if ($new_val < $self->{min2}) {
    die "min greater than max\n";
  }
  $self->{max2} = $new_val;
}

=head2 pairs

 Title   : pairs
 Usage   : my @pairs = $match->pairs;
 Function: return all the ChunkPair objects that have been add()ed to this Match
 Returns : a List of ChunkPair objects
 Args    : none

=cut

sub pairs
{
  return $_[0]->{pairs};
}

=head2 score

 Title   : score
 Usage   : $acc = $seq->score;
 Function: The score of this Match - longer match gives a higher score
 Returns : int - currently returns the total number of lines this match
           covers in both files
 Args    : None

=cut

sub score
{
  my $self = shift;
  return $self->{max1} - $self->{min1} + $self->{max2} - $self->{min2} + 2;
}


=head2 as_string

 Title   : as_string
 Usage   : my $str = $match->as_string
 Function: return a string representation of this Match
 Args    : none

=cut

sub as_string
{
  my $self = shift;

  return $self->min1 . ".." . $self->max1 . "==" . $self->min2 . ".." . $self->max2;
}

=head1 AUTHOR

Kim Rutherford <kmr+same@xenu.org.uk>

=head1 COPYRIGHT & LICENSE

Copyright 2005,2006 Kim Rutherford.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER

This module is provided "as is" without warranty of any kind. It
may redistributed under the same conditions as Perl itself.

=cut

1;
