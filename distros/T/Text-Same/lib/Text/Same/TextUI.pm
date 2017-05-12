=head1 NAME

Text::Same::TextUI

=head1 DESCRIPTION

functions for outputting the results of a comparison made with Text::Same::compare();

=head1 SYNOPSIS

Usage   : use Text::Same::TextUI;
          ...
          my $matchmap = compare(\%options, $file1, $file2);
          my @source1_non_matches = $matchmap->source1_non_matches;
          my @source2_non_matches = $matchmap->source2_non_matches;
          draw_non_matches(\%options, \@source1_non_matches, $matchmap->source1);
          draw_non_matches(\%options, \@source2_non_matches, $matchmap->source2);


=head1 METHODS

See below.  Methods private to this module are prefixed by an
underscore.

=cut

package Text::Same::TextUI;

use Exporter;
use vars qw($VERSION @EXPORT @ISA);
@ISA = qw( Exporter );
@EXPORT = qw( draw_match draw_non_match );

use warnings FATAL => 'all';
use strict;
use Carp;

$VERSION = '0.07';

use Text::Same::ChunkedSource;
use Text::Same::Util;

=head2 draw_non_match

 Title   : draw_non_match
 Usage   : draw_non_match(\%options, $source, $non_match);
 Function: return a string suitable to output that is a representation of
           a non matching region (range of chunk indexes) in a particular
           source
 Args    : %options - settings to use
           $source - the ChunkedSource that this non-match came from (for
                     looking up the actual chunks/lines for the range of
                     indexes)
           $non_match - a Range object representing the non-matching chunks

=cut

sub draw_non_match
{
  my $options = shift;
  my $source = shift;
  my $non_match_range = shift;
  my $screen_width = 78;

  if (defined $options->{term_width}) {
    $screen_width = $options->{term_width} - 2;
  }

  my $start = $non_match_range->start();
  my $end = $non_match_range->end();

  my $ret = "  " . ($start+1) . ".." . ($end+1) . ":\n";
  my @match_chunks = _get_match_chunks($options, $start, $end, $source);

  my $padding = "    ";

  for my $match_chunk (@match_chunks) {
    $match_chunk = substr $match_chunk, 0, $screen_width - length $padding;
    $ret .= $padding;
    $ret .= $match_chunk;
    $ret .= "\n";
  }

  return $ret;
}

=head2 draw_match

 Title   : draw_match
 Usage   : draw_match(\%options, $match);
 Function: return a string suitable to output that is a representation of
           a match between two sources
 Args    : %options - settings to use
           $match - a Match object representing the matching chunks

=cut

sub draw_match
{
  my $options = shift;
  my $match = shift;

  if ($options->{side_by_side}) {
    _draw_match_side_by_side($options, $match);
  } else {
    _draw_match_vertically($options, $match);
  }
}

sub _draw_match_side_by_side
{
  my $options = shift;
  my $match = shift;

  my $min1 = $match->min1;
  my $max1 = $match->max1;
  my $min2 = $match->min2;
  my $max2 = $match->max2;

  my $width = _get_term_width($options);

  my $half_width = int($width / 2 - 6);

  my $ret = "match " . ($min1+1) . ".." . ($max1+1) . "==" .
            ($min2+1) . ".." . ($max2+1) . "\n";

  my @start_context1 = _get_start_context($options, $min1, $match->source1);
  my @start_context2 = _get_start_context($options, $min2, $match->source2);
  my $max_start_context_len =
    scalar(@start_context1) > scalar(@start_context2) ?
      scalar(@start_context1) : scalar(@start_context2);

  my $context_format_str =
    "  %-${half_width}.${half_width}s   %-${half_width}.${half_width}s\n";
  my $match_format_str =
    "  %-${half_width}.${half_width}s %s %-${half_width}.${half_width}s\n";
  my $i;
  for ($i = 0; $i < $max_start_context_len; $i++) {
    if (defined $start_context1[$i] || defined $start_context2[$i]) {
      $ret .= sprintf $context_format_str,
        (defined $start_context1[$i] ? $start_context1[$i] : ""),
        (defined $start_context2[$i] ? $start_context2[$i] : "");
    }
  }

  my @match_chunks1 = _get_match_chunks($options, $min1, $max1,
                                        $match->source1);
  my @match_chunks2 = _get_match_chunks($options, $min2, $max2,
                                        $match->source2);
  my $next_indicator = undef;

  for ($i = 0; $i<scalar(@match_chunks1) or $i<scalar(@match_chunks2); $i++) {
    my $left_chunk = $match_chunks1[$i];
    if (defined $left_chunk) {
      $left_chunk =~ s/\t/    /g;
    }
    my $left_ignorable =
      defined $left_chunk && is_ignorable($options, $left_chunk);
    my $right_chunk = $match_chunks2[$i];
    if ($right_chunk) {
      $right_chunk =~ s/\t/    /g;
    }
    my $right_ignorable =
      defined $right_chunk && is_ignorable($options, $right_chunk);

    my $indicator;
    if ($left_ignorable && $right_ignorable) {
      if (defined $next_indicator) {
        $indicator = $next_indicator;
      } else {
        $indicator = "-";
      }
    } else {
      if (!$left_ignorable && !$right_ignorable) {
        $indicator = "|";
      } else {
        if ($left_ignorable) {
          # insert a blank on the right and try again
          splice(@match_chunks2, $i, 0, "");
          $next_indicator = "<";
          redo;
        } else {
          # insert a blank on the left and try again
          splice(@match_chunks1, $i, 0, "");
          $next_indicator = ">";
          redo;
        }
      }
    }

    $ret .= sprintf $match_format_str,
      (defined $left_chunk ? $left_chunk : ""),
      $indicator,
      (defined $right_chunk ? $right_chunk : "");

    $next_indicator = undef;
  }

  my @end_context1 = _get_end_context($options, $max1, $match->source1);
  my @end_context2 = _get_end_context($options, $max2, $match->source2);

  my $max_end_context_len =
    scalar(@end_context1) > scalar(@end_context2) ?
      scalar(@end_context1) : scalar(@end_context2);

  for ($i = 0; $i < $max_end_context_len; $i++) {
    if (defined $end_context1[$i] || defined $end_context2[$i]) {
      $ret .= sprintf $context_format_str,
        (defined $end_context1[$i] ? $end_context1[$i] : ""),
        (defined $end_context2[$i] ? $end_context2[$i] : "");
    }
  }


  return $ret;
}

sub _get_match_chunks
{
  my ($options, $min, $max, $source) = @_;

  my @ret = ();

  for (my $i = $min; $i <= $max; $i++) {
    my $text = ($source->get_all_chunks)[$i];
    $text =~ s/\t/    /g;
    push @ret, $text;
  }

  return @ret;
}

sub _get_start_context
{
  my ($options, $min, $source) = @_;

  my $context_chunks = $options->{context} || 3;
  my $context_min = $min - $context_chunks;

  my @ret = ();

  for (my $i = $context_min; $i < $min; $i++) {
    if ($i < 0) {
      push @ret, undef;
    } else {
      my $text = ($source->get_all_chunks)[$i];
      $text =~ s/\t/   /g;
      push @ret, $text;
    }
  }

  return @ret;
}

sub _get_end_context
{
  my ($options, $max, $source) = @_;

  my $context_chunks = $options->{context} || 3;
  my $context_max = $max + $context_chunks;

  my @ret = ();

  for (my $i = $max + 1; $i < $context_max; $i++) {
    if ($i > $source->get_all_chunks_count - 1) {
      push @ret, undef;
    } else {
      my $text = ($source->get_all_chunks)[$i];
      $text =~ s/\t/   /g;
      push @ret, $text;
    }
  }

  return @ret;
}

sub _draw_match_vertically
{
  my ($options, $match) = @_;

  my $ret = "match " . $match->as_string . "\n";

  $ret .= _draw_range_and_context($options, $match->min1, $match->max1,
                                 $match->source1);
  $ret .= "=== matches\n";

  $ret .= _draw_range_and_context($options, $match->min2, $match->max2,
                                 $match->source2);

}

sub _draw_range_and_context
{
  my ($options, $min, $max, $source) = @_;

  my $ret = "";

  for my $start_chunk_text (_get_start_context($options, $min, $source)) {
    if (defined $start_chunk_text) {
      $ret .= "   $start_chunk_text\n";
    }
  }

  for (my $i = $min; $i <= $max; $i++) {
    my $match_chunk_text = ($source->get_all_chunks)[$i];
    $ret .= "=  $match_chunk_text\n";
  }

  for my $end_chunk_text (_get_end_context($options, $max, $source)) {
    if (defined $end_chunk_text) {
      $ret .= "   $end_chunk_text\n";
    }
  }

  return $ret;
}

sub _get_term_width
{
  my $options = shift;
  if (defined $options->{term_width}) {
    return $options->{term_width};
  } else {
    return 80;
  }
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
