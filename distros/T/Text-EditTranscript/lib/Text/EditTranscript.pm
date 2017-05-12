package Text::EditTranscript;

use 5.008006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Text::EditTranscript ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	EditTranscript
);

our $VERSION = '0.07';


sub EditTranscript {
	my $str = shift;
	my $str2 = shift;

	my $dist;
	my $transcript;
	for (my $i = 0; $i <= length($str); $i++) {
		$dist->[$i]->[0] = $i;
		$transcript->[$i]->[0] = "D";
	}
	for (my $i = 0; $i <= length($str2); $i++) {
		$dist->[0]->[$i] = $i;
		$transcript->[0]->[$i] = "I";
	}


	my $cost;

	for (my $i = 1; $i <= length($str); $i++) {
		for (my $j = 1; $j <= length($str2); $j++) {
			if (substr($str,$i-1,1) eq substr($str2,$j-1,1)) {
				$cost = 0;
			}
			else {
				$cost = 1;
			}
			$dist->[$i]->[$j] = Min($dist->[$i-1]->[$j] + 1,
						$dist->[$i]->[$j-1] + 1,
						$dist->[$i-1]->[$j-1] + $cost);
			if ($dist->[$i]->[$j] eq $dist->[$i]->[$j-1] + 1) {
				$transcript->[$i]->[$j] = "I";
			}
			if ($dist->[$i]->[$j] eq $dist->[$i-1]->[$j]+1) {
				$transcript->[$i]->[$j] = "D";
			}
			if ($dist->[$i]->[$j] eq  $dist->[$i-1]->[$j-1] + $cost) {
				if ($cost eq 0) {
					$transcript->[$i]->[$j] = "-";
				}
				else {
					$transcript->[$i]->[$j] = "S";
				}
			}
		}
	}

	my $st = Traceback($transcript,length($str),length($str2));
	$st = scalar reverse $st;
	return $st;

}

sub Traceback {
	my $transcript = shift;
	my $i = shift;
	my $j = shift;

	my $string;

	while ($i > 0 || $j > 0) {
		if (defined $transcript->[$i]->[$j]) {
			$string .= $transcript->[$i]->[$j];
		}

		last if (!defined $transcript->[$i]->[$j]);  
				# to keep us from getting caught in loops
		if ($transcript->[$i]->[$j] eq "S" || $transcript->[$i]->[$j] eq "-") {
			$i-- if ($i > 0);
			$j-- if ($j > 0);
		}
		elsif ($transcript->[$i]->[$j] eq "I") {
			$j-- if ($j > 0);
		}
		else {
			$i-- if ($i > 0);
		}
	}

	return $string;
}


sub Min {
	my @list = @_;

	@list = sort {$a <=> $b} @list;

	return shift @list;
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Text::EditTranscript - Perl extension for determining the edit transcript between two strings

=head1 SYNOPSIS

  use Text::EditTranscript;
  print EditTranscript("foo","bar");

=head1 DESCRIPTION

The edit transcript is a sequence of operations to transform one string into another string.  The operations include 'Insertion', 'Deletion', and Substitution.  This module creates a string denoting the list of operations to transfer the second string into the first string where:

=over

=item -

No operation required.

=item S
 
The character from second string should be substituted into the first string.

=item D
 
The character in that position from the first string should be deleted.

=item I

The character in that position in the second string should be inserted into the first string at that position.

=back

This method uses the Levenshtein distance calculation to create the edit transcript.

=head2 EXAMPLES

=over

=item *


	$string1 = "bar";
	$string2 = "baz";
	print EditDistance($string1,$string2),"\n";


This will result in "--S".  Interpreted, this means that 'ba' matches in both strings and the 'z' in string2 should be replaced by 'r' in string1 in order for the strings to match.

=item * 

	$string1 = "This is a test";
	$string2 = "This isn't a test";
	print EditDistance($string1,$string2),"\n";

This will result in "-------III-------", implying that the characters in the eighth, ninth, and tenth positions should be inserted into the first string starting at position eight.

=back


=head1 SEE ALSO

Text::Levenshtein, Text::LevenshteinXS

=head1 AUTHOR

Leigh Metcalf, E<lt>leigh@fprime.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Leigh Metcalf

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
