package Text::Same;

=head1 NAME

Text::Same - Look for similarities between files or arrays

=head1 SYNOPSIS

    use Text::Same;

    my $matchmap = compare "file_1", "file_2", { ignore_whitespace => 1 };
    my $matchmap = compare \@records1,  \@records2,  { ignore_simple => 3 };

  or use the "psame" command:

    psame -a file_1 file_2 | more

=head1 DESCRIPTION

C<compare()> compares two files or arrays of strings and returns a MatchMap
object holding the results.

=cut

=head1 FUNCTIONS

=cut

use warnings;
use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT);
use Exporter;

@ISA = qw( Exporter );
@EXPORT = qw( compare );

$VERSION = '0.07';

use Text::Same::Match;
use Text::Same::ChunkPair;
use Text::Same::MatchMap;
use Text::Same::Cache;
use Text::Same::Util;

sub _process_hits
{
  my ($options, $this_chunk_indx, $seen_pairs_ref, $matching_chunk_indexes_ref,
      $this_chunked_source, $other_chunked_source) = @_;

  for my $other_chunk_indx (@$matching_chunk_indexes_ref) {
    my $chunk_pair = new Text::Same::ChunkPair($this_chunk_indx,
                                               $other_chunk_indx);
    my $pair_id = $chunk_pair->packed_pair();

    if (!exists $seen_pairs_ref->{$pair_id}) {
      my $this_prev_chunk_indx =
        $this_chunked_source->get_previous_chunk_indx($options,
                                                      $this_chunk_indx);
      my $other_prev_chunk_indx =
        $other_chunked_source->get_previous_chunk_indx($options,
                                                       $other_chunk_indx);

      if (defined $this_prev_chunk_indx && defined $other_prev_chunk_indx) {
        my $this_prev_chunk_text =
          $this_chunked_source->get_chunk_by_indx($this_prev_chunk_indx);
        my $other_prev_chunk_text =
          $other_chunked_source->get_chunk_by_indx($other_prev_chunk_indx);
        my $this_prev_hash =
          Text::Same::ChunkedSource::hash($options, $this_prev_chunk_text);
        my $other_prev_hash =
          Text::Same::ChunkedSource::hash($options, $other_prev_chunk_text);

        if ($this_prev_hash eq $other_prev_hash) {
          my $prev_pair_id =
            Text::Same::ChunkPair::make_packed_pair($this_prev_chunk_indx,
                                                    $other_prev_chunk_indx);
          my $prev_match = $seen_pairs_ref->{$prev_pair_id};

          if (defined $prev_match) {
            $prev_match->add($chunk_pair);
            $seen_pairs_ref->{$pair_id} = $prev_match;
            next;
          }
        }
      }

      my $match = new Text::Same::Match(source1=>$this_chunked_source,
                                        source2=>$other_chunked_source,
                                        pairs=>[$chunk_pair]);
      $seen_pairs_ref->{$pair_id} = $match;
    }
  }
}

sub _find_matches($$$)
{
  my ($options, $source1, $source2) = @_;

  my $source1_chunk_indexes = $source1->get_filtered_chunk_indexes($options);

  my %seen_pairs = ();

  for my $this_chunk_indx (@$source1_chunk_indexes) {
    my $chunk_text = $source1->get_chunk_by_indx($this_chunk_indx);
    my @matching_chunk_indexes =
      $source2->get_matching_chunk_indexes($options, $chunk_text);

    if (@matching_chunk_indexes) {
      _process_hits($options, $this_chunk_indx, \%seen_pairs,
                    \@matching_chunk_indexes, $source1, $source2);
    }
  }

  return \%seen_pairs;
}

sub _extend_matches
{
  my ($options, $matches, $source1, $source2) = @_;

  for my $match (@$matches) {
    my ($prev, $next) = undef;

    $prev = $source1->get_previous_chunk_indx($options, $match->min1());
    if (defined $prev) {
      $match->set_min1($prev + 1);
    } else {
      $match->set_min1(0);
    }
    $prev = $source2->get_previous_chunk_indx($options, $match->min2());
    if (defined $prev) {
      $match->set_min2($prev + 1);
    } else {
      $match->set_min2(0);
    }
    $next = $source1->get_next_chunk_indx($options, $match->max1());
    if (defined $next) {
      $match->set_max1($next - 1);
    } else {
      $match->set_max1($source1->get_all_chunks_count() - 1);
    }
    $next = $source2->get_next_chunk_indx($options, $match->max2());
    if (defined $next) {
      $match->set_max2($next - 1);
    } else {
      $match->set_max2($source2->get_all_chunks_count() - 1);
    }
  }
}

=head2 compare

 Title   : compare
 Usage   : $matchmap = compare($options, $file1, $file2)
        or
           $matchmap = compare($options, \@array1, \@array2)
        then:
           my @all_matches = $matchmap->all_matches;
 Function: return a MatchMap object holding matches and non-matches between the
           two given files or arrays of strings

=cut

sub compare
{
  my $options = shift || {};
  my $data1 = shift;
  my $data2 = shift;

  my $cache = new Text::Same::Cache();

  my $source1;

  if (ref $data1 eq "ARRAY") {
    $source1 = new Text::Same::ChunkedSource(name=>"array1", chunks=>$data1);
  } else {
    $source1 = $cache->get($data1, $options);
  }

  my $source2;

  if (ref $data2 eq "ARRAY") {
    $source2 = new Text::Same::ChunkedSource(name=>"array2", chunks=>$data2);
  } else {
    $source2 = $cache->get($data2, $options);
  }

  my $seen_pairs_ref = _find_matches $options, $source1, $source2;

  my @matches = values %{$seen_pairs_ref};
  my %uniq_matches = ();

  for my $match (@matches) {
    $uniq_matches{$match} = $match;
  }

  my @unique_matches = values %uniq_matches;

  _extend_matches($options, \@unique_matches, $source1, $source2);

  return new Text::Same::MatchMap(options=>$options, source1=>$source1,
                                  source2=>$source2,
                                  matches=>\@unique_matches);
}

=head1 SEE ALSO

B<psame(1)>

=head1 AUTHOR

Kim Rutherford <kmr+same@xenu.org.uk>

=head1 COPYRIGHT & LICENSE

Copyright 2005,2006 Kim Rutherford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
