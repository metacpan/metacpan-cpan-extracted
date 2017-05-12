package Text::Levenshtein::Damerau::PP;
use 5.008_008;    # for utf8, sorry legacy Perls
use strict;
use List::Util qw/min/;
require Exporter;
 
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/pp_edistance/;
our $VERSION   = '0.25';

sub pp_edistance {
    # Does the actual calculation on a pair of strings
    my ( $source, $target, $max_distance ) = @_;
    $max_distance = int($max_distance || 0);

    my $source_length = length($source) || 0;
    my $target_length = length($target) || 0;
    return ($source_length?$source_length:$target_length) if(!$target_length || !$source_length);

    my $lengths_max = $source_length + $target_length;
    my $dictionary_count;    #create dictionary to keep character count
    my $swap_count;          
    my $swap_score;          
    my $target_char_count;   
    my $source_index;
    my $target_index;
    my @scores;              

    # init values outside of work loops
    $scores[0][0] = $scores[1][0] = $scores[0][1] = $lengths_max;
    $scores[1][1] = 0;

    # Work Loops
    foreach $source_index ( 1 .. $source_length ) {
        $swap_count = 0;
        $dictionary_count->{ substr( $source, $source_index - 1, 1 ) } = 0;
        $scores[ $source_index + 1 ][1] = $source_index;
        $scores[ $source_index + 1 ][0] = $lengths_max;

        foreach $target_index ( 1 .. $target_length ) {
            if ( $source_index == 1 ) {
                $dictionary_count->{ substr( $target, $target_index - 1, 1 ) } = 0;
                $scores[1][ $target_index + 1 ] = $target_index;
                $scores[0][ $target_index + 1 ] = $lengths_max;
            }

            $target_char_count =
              $dictionary_count->{ substr( $target, $target_index - 1, 1 ) };
	     $swap_score = $scores[$target_char_count][$swap_count] +
                  ( $source_index - $target_char_count - 1 ) + 1 +
                  ( $target_index - $swap_count - 1 );

            if (
                substr( $source, $source_index - 1, 1 ) ne
                substr( $target, $target_index - 1, 1 ) )
            {
                $scores[ $source_index + 1 ][ $target_index + 1 ] = min(
                    $scores[$source_index][$target_index]+1,
                    $scores[ $source_index + 1 ][$target_index]+1,
                    $scores[$source_index][ $target_index + 1 ]+1,
                    $swap_score
                );
            }
            else {
                $swap_count = $target_index;

                $scores[ $source_index + 1 ][ $target_index + 1 ] = min(
                  $scores[$source_index][$target_index], $swap_score
                );
            }
        }

        #unless ( $max_distance == 0 || $max_distance >= $scores[ $source_index + 1 ][ $target_length + 1 ] )
        #{
        #    return -1;
        #}

        $dictionary_count->{ substr( $source, $source_index - 1, 1 ) } =
          $source_index;
    }
 
    my $score = $scores[$source_length+1][$target_length+1];
    return ($max_distance != 0 && $max_distance < $score)?(-1):$score;
}
 
1;

__END__

=encoding utf8

=head1 NAME

Text::Levenshtein::Damerau::PP - Pure Perl Damerau Levenshtein edit distance.

=head1 SYNOPSIS

	use Text::Levenshtein::Damerau::PP qw/pp_edistance/;

	print pp_edistance('Neil','Niel');
	# prints 1

=head1 DESCRIPTION

Returns the true Damerau Levenshtein edit distance of strings with adjacent transpositions. Pure Perl implementation. Works correctly with utf8.

	use Text::Levenshtein::Damerau::PP qw/pp_edistance/;
	use utf8;

	pp_edistance('ⓕⓞⓤⓡ','ⓕⓤⓞⓡ'), 
	# prints 1

=head1 METHODS

=head2 pp_edistance

Arguments: source string and target string. 

=over

=item * I<OPTIONAL 3rd argument> int (max distance; only return results with $int distance or less). 0 = unlimited. Default = 0.

=back

Returns: int that represents the edit distance between the two argument. Stops calculations and returns -1 if max distance is set and reached.

Function to take the edit distance between a source and target string. Contains the actual algorithm implementation. 

	use Text::Levenshtein::Damerau::PP qw/pp_edistance/;
	print pp_edistance('Neil','Niel');
	# prints 1

	print pp_edistance('Neil','Nielx',1);
	# prints -1


=head1 SEE ALSO

=over 4

=item * L<Text::Levenshtein::Damerau>

=item * L<Text::Levenshtein::Damerau::XS>

=back

=head1 BUGS

Please report bugs to:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Levenshtein-Damerau>

=head1 AUTHOR

Nick Logan <F<ug@skunkds.com>>

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut


