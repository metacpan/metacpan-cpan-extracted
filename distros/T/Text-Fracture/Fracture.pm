#
# Fracture.pm
#
# Copyright (c) 2007-2008, Juergen Weigert, Novell Inc.
# This module is free software. It may be used, redistributed
# and/or modified under the same terms as perl.
#

package Text::Fracture;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(init fract) ] );	# exportable
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();					# autoexport
our $VERSION = '1.02';

require XSLoader;
XSLoader::load('Text::Fracture', $VERSION);

sub fract
{
  my $r = do_fract(@_);

  # do_fract() may put an empty element at the end of the list. 
  # check for that and clean up.
  # (This cleanup code is easier done in perl than in C.)

  # a) an empty element may be trailing.
  pop @$r if $r and $r->[-1] and ($r->[-1][1] == 0);

  # b) our end of file recognition always has one newline too many at the end.
  $r->[-1][3]-- if $r and $r->[-1];

  return $r;
}

1;
__END__

=head1 NAME

Text::Fracture -- Split a text into logical fragments

=head1 SYNOPSIS

  use Text::Fracture qw(init fract);

  init({ max_lines => 20, max_cpl => 300, max_chars => 2000 });
  my $text = { open my $fh, "/etc/termcap"; local $/; <$fh> };
  my $aref = fract($text);
  # [ 
  #   [ $offset=0,       $length, $lines_offset=1,       $line_count ], 
  #   [ $off2=$length,     $len2, $l_off2=$line_count,       $l_cnt2 ], 
  #   [ $off3=$off2+$len2, $len3, $l_off3=$l_off3+$l_cnt2-1, $l_cnt3 ], 
  # ...
  # ]


=head1 DESCRIPTION

This module implements a text subdivision technique.  It generates a list of
logical fragments (paragraphs/chunks/snippets) from the input text;

The border of a logical fragement is primarily defined by blank lines.  (e.g.
"\n\n"). Add ing a few blank lines near the beginning of the input text is
obviously likely to change end of the fragment where this change is in. Once
the end of a previous fragment changes, one might expect that all subsequent
fragments are likely to change place too.
The chosen algorithm tries to prevent such effects to a large degree. Thus
local text changes can be expected to only have a local effect on one or few
fragments.

Further details how the algorithm works can be seen in the source.
An description of an early implementation is given below.

A fragment will have up to C<max_lines> newline characters
("\n") after applying the following rules:

 * Carriage-return newline character combinations ("\r\n", "\n\r") or
   carriage-return characters ("\r") are all counted if they were newline
   characters.  (Motivation: make blank line recognition independent of file
   type.)

 * A line longer than C<max_cpl> has its last non-alphanumeric character before
   the C<max_cpl> position handled as if it were a newline character.
   (Motivation: handle the absence of newline characters gracefully)

 * [Outdated] In the absence of blank lines, the shortest logical text line between line
   number C<min_lines> and C<max_lines> is counted as if followed by a blank
   line.  (Motivation: handle the absence of blank lines gracefully)
 
 * [Outdated] The last C<readaheadsz> characters of a line may be repeated without
   increasing the logical length of the line.  (Motivation: Make ascii-art
   rulers very likley to be come fragment ends.)

 * [Outdated] Lines that only contain characters found in the last C<readaheadsz> of a
   fragment are considered part of the fragment.  (Motivation: include all
   closing braces of a nested code block in the same fragment, up to but not
   including the next keyword.)

 * If the previous line began with whitespace and this line does not, 
   it is a candidate for a new fragment.
   (Motivation: End of indentation indcates something new.)

 * If, after skipping any whitespace, the previous line began with a
   non-alphanumeric character, and this line begins (again after skipping
   whitespace) with an alphanumeric character, or vice versa, it is a candidate
   for a new fragment. '$' and '_' count as alphanumeric in this context.
   (Motivation: Comment characters '%#//*"' and blockbuilding structures '(){}[]' are 
   thus separated from keywords or names, which often introduce new logical blocks.)

This ruleset is intended to work equally well with source code, plain text,
XML, HTML, postscript, or other textual file formats.

The return value of fract() is a reference to an array of arrays. Each of which 
has 4 numeric elements. These are:

 * byte_offset of the first byte in the fragment.

 * length of the fragment in bytes. Including trailing newline characters.

 * offset of the fragement in lines.

 * number_of_lines in the fragment.

The number_of_lines is normally equal to the number of newline characters in the fragment.
In the last fragment, the number_of_lines may be one more than the number of newline characters
if there is no trailing newline character. E.g. the fragments "foo\nbar\n" and "foo\nbar" are 
both reported as two lines long.

init() should be called before the first call to frac(). 
It need only be called again to change one of its parameters.

=head1 BUGS

Text::Fracture is not a parser, thus no semantics 
are used to find logical fragment ends.
This is more of a feature than a bug.

The algorithm for finding logical fragment ends employs heuristics. 
This may or may not agree with human perception or with the factual 
structure of the text.

The placement of fragment borders can depend on inserts or deletes in the text.
Thus fragments may not be recognized as identical if text was changed in their neighbouring fragments. A local change can have global effects, under rare circumstances.

An extensive test suite is missing.

=head1 AUTHOR

Juergen Weigert <jw@suse.de>

=head1 COPYRIGHT AND LEGALESE

Copyright (c) 2007-2008, Juergen Weigert, Novell Inc.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

