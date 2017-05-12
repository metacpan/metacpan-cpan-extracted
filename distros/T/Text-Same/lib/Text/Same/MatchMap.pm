=head1 NAME

Text::Same::MatchMap

=head1 DESCRIPTION

Objects of this class are returned by Text::Same::compare() and hold the
results of comparison in a convenient form.

=head1 SYNOPSIS

 use Text::Same;
 use Text::Same::TextUI;

 my $matchmap = compare(\%options, $file1, $file2);

 if ($options{show_matches}) {
   my @matches = $matchmap->matches;

   for my $match (@matches) {
     if (!defined $options{min_score} or $match->score >= $options{min_score}) {
       print draw_match(\%options, $match);
     }
   }
 }

=head1 METHODS

See below.  Methods private to this module are prefixed by an
underscore.

=cut

package Text::Same::MatchMap;

use warnings;
use strict;
use Carp;

use vars qw($VERSION);
$VERSION = '0.07';

use Text::Same::Range;

=head2 new

 Title   : new
 Usage   : $matchmap = new Text::Same::MatchMap(options=>$options,
                                                source1=>$source1,
                                                source2=>$source2,
                                                seen_pairs=>\%seen_pairs);
 Function: Creates a new MatchMap object for a comparison
 Returns : A Text::Same::MatchMap object
 Args    : options - the options used by Text::Same::compare();
           source1 - a ChunkedSource for the first source
           source2 - a ChunkedSource for the second source
           seen_pairs - a hash from ChunkPair to Match object, used during
                        comparison to record which pairs of chunks (ie.
                        pairs of lines) have been assigned to a Match

=cut

sub new
{
  my $arg  = shift;
  my $class = ref($arg) || $arg;
  my %args = @_;

  my $self = {options=>$args{options}, source1=>$args{source1}, source2=>$args{source2}};

  my @sorted_matches =
    sort {
      $a->{min1} <=> $b->{min1}
        ||
      $a->{min2} <=> $b->{min2};
    } @{$args{matches}};

  $self->{matches} = \@sorted_matches;

  bless $self, $class;

  return $self;
}

=head2 source1

 Title   : source1
 Usage   : $source = $matchmap->source1();
 Function: returns the source1 argument to new()

=cut

sub source1
{
  my $self = shift;
  return $self->{source1};
}


=head2 source2

 Title   : source2
 Usage   : $source = $matchmap->source2();
 Function: returns the source2 argument to new()

=cut

sub source2
{
  my $self = shift;
  return $self->{source2};
}

sub _find_matched_ranges
{
  my $self = shift;
  my @matches = $self->matches;

  my %indx_to_matches1 = ();
  my %indx_to_matches2 = ();

  for my $match (@matches) {
    my $i;
    for ($i = $match->min1; $i <= $match->max1; ++$i) {
      push @{$indx_to_matches1{$i}}, $match;
    }
    for ($i = $match->min2; $i <= $match->max2; ++$i) {
      push @{$indx_to_matches2{$i}}, $match;
    }
  }

  return (\%indx_to_matches1, \%indx_to_matches2);
}

sub _find_unmatched_chunks
{
  my $self = shift;
  my $source1 = shift;
  my $source2 = shift;

  my ($indx_to_matches1, $indx_to_matches2) = $self->_find_matched_ranges();

  $self->{source1_non_matches} = _get_non_matches($source1, $indx_to_matches1);
  $self->{source2_non_matches} = _get_non_matches($source2, $indx_to_matches2);
}

sub _get_non_matches
{
   my $source = shift;
   my $indx_to_matches_ref = shift;
   my %indx_to_matches = %{$indx_to_matches_ref};
   my @non_matches = ();
   my $max_chunk = $source->get_all_chunks_count;
   my $current_min = undef;

   if ($max_chunk == 0) {
     return [];
   }

   if (!exists $indx_to_matches{0}) {
     $current_min = 0;
   }

   for (my $i = 1; $i < $max_chunk; $i++) {
     if (defined $current_min) {
       if (exists $indx_to_matches{$i}) {
         push @non_matches, new Text::Same::Range($current_min, $i - 1);
         $current_min = undef;
       }
     } else {
       if (!exists $indx_to_matches{$i}) {
         $current_min = $i;
       }
     }
   }

   if (defined $current_min) {
     push @non_matches, new Text::Same::Range($current_min, $max_chunk - 1);
   }

   return \@non_matches;
}


=head2 matches

 Title   : matches
 Usage   : my @matches = $matches->matches();
 Function: return the Match objects from the seen_pairs argument to new()

=cut

sub matches
{
  my $self = shift;
  return @{$self->{matches}};
}


=head2 source1_non_matches

 Title   : source1_non_matches
 Usage   : my @ranges = $matchmap->source1_non_matches();
 Function: return the ranges of chunks/lines from source1 that didn't match
           any lines from source2

=cut

sub source1_non_matches
{
  my $self = shift;
  if (!defined $self->{source1_non_matches}) {
    $self->_find_unmatched_chunks($self->{source1}, $self->{source2});
  }
  return @{$self->{source1_non_matches}};
}

=head2 source2_non_matches

 Title   : source2_non_matches
 Usage   : my @ranges = $matchmap->source2_non_matches();
 Function: return the ranges of chunks/lines from source2 that didn't match
           any lines from source1

=cut

sub source2_non_matches
{
  my $self = shift;
  if (!defined $self->{source2_non_matches}) {
    $self->_find_unmatched_chunks($self->{source1}, $self->{source2});
  }
  return @{$self->{source2_non_matches}};
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
