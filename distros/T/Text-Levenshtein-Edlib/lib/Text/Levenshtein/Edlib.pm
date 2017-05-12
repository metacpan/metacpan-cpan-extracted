package Text::Levenshtein::Edlib;

use 5.014000;
use strict;
use warnings;
use Carp;
use parent qw/Exporter/;

my @constants =
  qw/
		EDLIB_CIGAR_EXTENDED
		EDLIB_CIGAR_STANDARD
		EDLIB_EDOP_DELETE
		EDLIB_EDOP_INSERT
		EDLIB_EDOP_MATCH
		EDLIB_EDOP_MISMATCH
		EDLIB_MODE_HW
		EDLIB_MODE_NW
		EDLIB_MODE_SHW
		EDLIB_STATUS_ERROR
		EDLIB_STATUS_OK
		EDLIB_TASK_DISTANCE
		EDLIB_TASK_LOC
		EDLIB_TASK_PATH/;

our %EXPORT_TAGS =
  (all => [ @constants, qw/align distance to_cigar/ ], constants => \@constants);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = ( @{ $EXPORT_TAGS{'constants'} } );
our $VERSION = '0.001001';

require XSLoader;
XSLoader::load('Text::Levenshtein::Edlib', $VERSION);

sub AUTOLOAD {
	# This AUTOLOAD is used to 'autoload' constants from the constant()
	# XS function.

	my $constname;
	our $AUTOLOAD;
	($constname = $AUTOLOAD) =~ s/.*:://;
	croak "&Text::Levenshtein::Edlib::constant not defined" if $constname eq 'constant';
	my ($error, $val) = constant($constname);
	if ($error) { croak $error; }
	{
		no strict 'refs';
		*$AUTOLOAD = sub { $val };
	}
	goto &$AUTOLOAD;
}

sub align {
	my ($q, $t, $k, $mode, $task) = @_;
	$k //= -1;
	$mode //= EDLIB_MODE_NW();
	$task //= EDLIB_TASK_PATH();
	my $result = edlibAlign($q, $t, $k, $mode, $task);
	my ($dist, $alpha_len, $end, $start, $align) = @$result;
	return {} if $dist == -1;
	my %ret;
	$ret{editDistance}   = $dist;
	$ret{alphabetLength} = $alpha_len;
	$ret{endLocations}   = $end   if defined $end;
	$ret{startLocations} = $start if defined $start;
	$ret{alignment}      = $align if defined $align;
	\%ret
}

sub distance {
	my ($q, $t, $k, $mode) = @_;
	align($q, $t, $k, $mode, EDLIB_TASK_DISTANCE())->{editDistance}
}

sub to_cigar {
	my ($align, $format) = @_;
	$align = pack 'C*', @$align;
	$format //= EDLIB_CIGAR_STANDARD();
	edlibAlignmentToCigar($align, $format);
}

1;
__END__

=encoding utf-8

=head1 NAME

Text::Levenshtein::Edlib - XS edit distance and optimal alignment path calculation

=head1 SYNOPSIS

  use feature 'say';

  use Text::Levenshtein::Edlib qw/:all/;
  say distance 'kitten', 'sitting'; # prints '3'
  say 'Distance > 2!'
      if !defined distance 'kitten', 'sitting', 2; # prints 'Distance > 2!'

  my $align = align('kitten', 'sitting');
  say "Edit distance is: $align->{editDistance}";
  say "Alphabet length is: $align->{alphabetLength}";
  say "Start locations are: @{$align->{startLocations}}";
  say "End locations are: @{$align->{endLocations}}";
  say "Alignment path is: @{$align->{alignment}}";
  say "Alignment path (in CIGAR format): ", to_cigar $align->{alignment};
  say "Alignment path (in extended CIGAR format): ",
      to_cigar $align->{alignment}, EDLIB_CIGAR_EXTENDED;

=head1 DESCRIPTION

Text::Levenshtein::Edlib is a wrapper around the edlib library that
computes Levenshtein edit distance and optimal alignment path for a
pair of strings.

It B<does not handle UTF-8 strings>, for those
L<Text::Levenshtein::XS> can compute edit distance but not alignment
path.

This module has two functions:

=over

=item B<distance>(I<$query>, I<$target>, [I<$max_distance>, [I<$mode>]])

This is the basic interface to the library. It is compatible with the
function of the same name in L<Text::Levenshtein::XS>.

It returns the edit distance between the two given strings. If the
third argument is specified, and the edit distance is greater than the
value of the third argument, then the function finishes the
computation early and returns undef. See below for the meaning of the
optional I<$mode> argument.

=item B<align>(I<$query>, I<$target>, [I<$max_distance>, [I<$mode>, [I<$task>]]])

This is the full-featured interface to the library.

It returns a hashref with the following keys:

=over

=item C<editDistance>

The edit distance of the two strings.

=item C<alphabetLength>

The number of different characters in the query and target together.

=item C<endLocations>

Array of zero-based positions in target where optimal alignment paths
end. If gap after query is penalized, gap counts as part of query
(NW), otherwise not.

=item C<startLocations>

Array of zero-based positions in target where optimal alignment paths
start, they correspond to endLocations. If gap before query is
penalized, gap counts as part of query (NW), otherwise not.

=item C<alignment>

Alignment is found for first pair of start and end locations.
Alignment is sequence of numbers: 0, 1, 2, 3. 0 stands for match. 1
stands for insertion to target. 2 stands for insertion to query. 3
stands for mismatch. You can use the C<EDLIB_EDOP_*> constants instead
of 0, 1, 2, and 3. Alignment aligns query to target from begining of
query till end of query. If gaps are not penalized, they are not in
alignment.

=back

The third argument, I<$max_distance>, works similarly to the third
argument of B<distance>: if the distance is more than its value, this
function returns an empty hashref. Default value is -1, which disables
this optimization.

The fourth argument, I<$mode>, chooses how Edlib should treat gaps
before and after query. The options are:

=over

=item C<EDLIB_MODE_NW> (default)

Global method - gaps are not ignored. This is the standard Levenshtein
distance, and is the default if I<$mode> is not specified.

=item C<EDLIB_MODE_SHW>

Prefix method - gaps at query end are ignored. So the edit distance
between C<AACT> and C<AACTGGC> is 0, because we can ignore the C<GGC>
at the end.

=item C<EDLIB_MODE_HW>

Infix method - gaps at both query start and end are ignored. So the
edit distance between C<ACT> and C<CGACTGAC> is 0, because C<CG> at
the beginning and C<GAC> at the end of the target are ignored.

=back

The fifth argument, I<$task>, chooses what we want to compute. The options are:

=over

=item C<EDLIB_TASK_PATH> (default, slowest)

All the keys described above will be computed.

=item C<EDLIB_TASK_LOC>

All keys except for C<alignment> will be computed.

=item C<EDLIB_TASK_DISTANCE> (fastest)

All keys except for C<alignment> and C<startLocations> will be computed.

=back

The less the function computes, the faster it runs.

=back

=head2 EXPORT

All constants by default. You can export the functions C<align>,
C<distance> and C<to_cigar> and any of the constants below. You can
use the tags C<:constants> to export every constant, and C<:all> to
export every constant, C<align>, C<distance> and C<to_cigar>.

=head2 Exportable constants

  EDLIB_CIGAR_EXTENDED
  EDLIB_CIGAR_STANDARD
  EDLIB_EDOP_DELETE
  EDLIB_EDOP_INSERT
  EDLIB_EDOP_MATCH
  EDLIB_EDOP_MISMATCH
  EDLIB_MODE_HW
  EDLIB_MODE_NW
  EDLIB_MODE_SHW
  EDLIB_STATUS_ERROR
  EDLIB_STATUS_OK
  EDLIB_TASK_DISTANCE
  EDLIB_TASK_LOC
  EDLIB_TASK_PATH

=head1 SEE ALSO

L<https://github.com/Martinsos/edlib/>, L<http://martinsosic.com/edlib/edlib_8h.html>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
