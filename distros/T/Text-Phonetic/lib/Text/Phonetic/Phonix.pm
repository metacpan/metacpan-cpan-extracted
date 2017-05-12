# ============================================================================
package Text::Phonetic::Phonix;
# ============================================================================
use utf8;

use Moo;
extends qw(Text::Phonetic);

__PACKAGE__->meta->make_immutable;

our $VERSION = $Text::Phonetic::VERSION;

our $VOVEL = '[AEIOU]';
our $VOVEL_WITHY = '[AEIOUY]';
our $CONSONANT = '[BCDFGHJLMNPQRSTVXZXY]';

our @VALUES = (
    [qr/[AEIOUHWY]/,0],
    [qr/[BP]/,1],
    [qr/[CGJKQ]/,2],
    [qr/[DT]/,3],
    [qr/L/,4],
    [qr/[MN]/,5],
    [qr/R/,6],
    [qr/[FV]/,7],
    [qr/[SXZ]/,8],
);

our @RULES = (
    [qr/DG/,'G'],
    [qr/C([OAU])/,'K1'],
    [qr/C[YI]/,'SI'],
    [qr/CE/,'SE'],
    [qr/^CL($VOVEL)/,'KL1'],
    [qr/CK/,'K'],
    [qr/[GJ]C$/,'K'],
    [qr/^CH?R($VOVEL)/,'KR1'],
    [qr/^WR/,'R'],
    [qr/NC/,'NK'],
    [qr/CT/,'KT'],
    [qr/PH/,'F'],
    [qr/AA/,'AR'], #neu
    [qr/SCH/,'SH'],
    [qr/BTL/,'TL'],
    [qr/GHT/,'T'],
    [qr/AUGH/,'ARF'],
    [qr/($VOVEL)LJ($VOVEL)/,'1LD2'],
    [qr/LOUGH/,'LOW'],
    [qr/^Q/,'KW'],
    [qr/^KN/,'N'],
    [qr/GN$/,'N'],
    [qr/GHN/,'N'],
    [qr/GNE$/,'N'],
    [qr/GHNE/,'NE'],
    [qr/GNES$/,'NS'],
    [qr/^GN/,'N'],
    [qr/(\w)GN($CONSONANT)/,'1N2'],
    [qr/^PS/,'S'],
    [qr/^PT/,'T'],
    [qr/^CZ/,'C'],
    [qr/($VOVEL)WZ(\w)/,'1Z2'],
    [qr/(\w)CZ(\w)/,'1CH2'],
    [qr/LZ/,'LSH'],
    [qr/RZ/,'RSH'],
    [qr/(\w)Z($VOVEL)/,'1S2'],
    [qr/ZZ/,'TS'],
    [qr/($CONSONANT)Z(\w)/,'1TS2'],
    [qr/HROUGH/,'REW'],
    [qr/OUGH/,'OF'],
    [qr/($VOVEL)Q($VOVEL)/,'1KW2'],
    [qr/($VOVEL)J($VOVEL)/,'1Y2'],
    [qr/^YJ($VOVEL)/,'Y1'],
    [qr/^GH/,'G'],
    [qr/($VOVEL)E$/,'1GH'],
    [qr/^CY/,'S'],
    [qr/NX/,'NKS'],
    [qr/^PF/,'F'],
    [qr/DT$/,'T'],
    [qr/(T|D)L$/,'1IL'],
    [qr/YTH/,'ITH'],
    [qr/^TS?J($VOVEL)/,'CH1'],
    [qr/^TS($VOVEL)/,'T1'],
    [qr/TCH/,'CH'], # old che
    [qr/($VOVEL)WSK/,'1VSIKE'],
    [qr/^[PM]N($VOVEL)/,'N1'],
    [qr/($VOVEL)STL/,'1SL'],
    [qr/TNT$/,'ENT'],
    [qr/EAUX$/,'OH'],
    [qr/EXCI/,'ECS'],
    [qr/X/,'ECS'],
    [qr/NED$/,'ND'],
    [qr/JR/,'DR'],
    [qr/EE$/,'EA'],
    [qr/ZS/,'S'],
    [qr/($VOVEL)H?R($CONSONANT)/,'1AH2'],
    [qr/($VOVEL)HR$/,'1AH'],
    [qr/RE$/,'AR'],
    [qr/($VOVEL)R$/,'1AH'],
    [qr/LLE/,'LE'],
    [qr/($CONSONANT)LE(S?)$/,'1ILE2'],
    [qr/E$/,''],
    [qr/ES$/,'S'],
    [qr/($VOVEL)SS/,'1AS'],
    [qr/($VOVEL)MB$/,'1M'],
    [qr/MPTS/,'MPS'],
    [qr/MPS/,'MS'],
    [qr/MPT/,'MT'],

);

#sub _do_compare {
#	my $obj = shift;
#	my $result1 = shift;
#	my $result2 = shift;
#
#	# Main values are different
#	return 0 unless ($result1->[0] eq $result2->[0]);
#	
#	# Ending values the same
#	return 75 if ($result1->[1] eq $result2->[1]);
#	
#	# Ending values differ in length, and are same for the shorter
#	my $length1 = length $result1->[1];
#	my $length2 = length $result2->[1];
#	if ($length1 > $length2
#		&& $length1 - $length2 == 1) {
#		return 50 if (substr($result1->[1],0,$length2) eq $result2->[1]);
#	 }elsif ($length2 > $length1
#		&& $length2 - $length1 == 1) {	
#		return 50 if (substr($result2->[1],0,$length1) eq $result1->[1]);
#	}
#	
#	return 25;
#}
#The algorithm always returns either a scalar value or an array reference with 
#two elements. The fist element represents the sound of the name without the 
#ending sound, and the second element represents the ending sound. To get a 
#full representation of the name you need to concat the two elements.
#
#If you want to compare two names the following rules apply:
#
#=over
#
#=item * If the ending sound values of an entered name and a retrieved name are 
#the same, the retrieved name is a LIKELY candidate.
#
#=item * If an entered name has an ending-sound value, and the retrieved name 
#does not, then the retrieved name is a LEAST-LIKELY candidate.
#
#=item * If the two ending-sound values are the same for the length of the 
#shorter, and the difference in length between the two ending-sound is one 
#digit only, then the retrieved name isa LESS-LIKELY candidate.
#
#=item * All other cases result in LEAST-LIKELY candidates.
#
#=back

sub _do_encode {
    my ($self,$string) = @_;
    
    my ($original_string, $first_char);
    $original_string = $string;
    
    # To uppercase and remove other characters
    $string = uc($string);
    $string =~ tr/A-Z//cd;
    
    # RULE 1: Replcace rule
    foreach my $rule (@RULES) {
        my $regexp = $rule->[0];
        my $replace = $rule->[1];
        $string =~ s/$regexp/_replace($replace,$1,$2)/ge;
    }
    
    # RULE 2: Fetch first character
    $first_char = substr($string,0,1,'');
    
    # RULE 3: Exceptions for first character rule
    if (grep { $first_char eq $_ } qw(A E I O U Y)) {
        $first_char = 'v';
        $string =~ s/^$VOVEL_WITHY//;
    } elsif ($first_char eq 'W' || $first_char eq 'H') {
        #$string =~ s/^[WH]//;
    }
    
    # RULE 4
    $string =~ s/ES$/S/;
    # RULE 5
    $string =~ s/($VOVEL_WITHY)$/$1E/;
    # RULE 6
    #$string =~ s/\w$//; # This rule seems kind of strict
    # RULE 7-8
#   if ($string =~ s/($VOVEL_WITHY)([A-Z]+)$/$2/) {
#       # RULE 13
#       $last_string = _transform($2);
#   }
    
    # RULE 9-11
    $string = _transform($string);
    
    # RULE 12
    $string = $first_char.$string;
    
    #$string .= $last_string if (defined $last_string);
    $string .= '0'  x (8-length $string);
    $string = substr($string,0,8);
    
    return $string;
}

sub _transform {
    my $string = shift;
    return unless defined $string;
    
    # RULE 9
    $string =~ s/([AEIOUYHW])//g;
    # RULE 10
    $string =~ s/($CONSONANT+)\1/$1/g;
    # RULE 11
    foreach my $value (@VALUES) {
        my $regexp = $value->[0];
        $string =~ s/$regexp/$value->[1]/g;
    }
    return $string;
}

sub _replace {
    my $replace = shift;
    my $pos1 = shift;
    my $pos2 = shift;
    
    $replace =~ s/1/$pos1/ if (defined $pos1);
    $replace =~ s/2/$pos2/ if (defined $pos2);
    
    return $replace;
}

1;

=encoding utf8

=pod

=head1 NAME

Text::Phonetic::Phonix - Phonix algorithm

=head1 DESCRIPTION

Phonix is an improved version of Soundex, developed by T.N. Gadd. Phonix 
has been incorporated into a number of WAIS implementations, including 
freeWAIS.

There seem to be two variants of the Phonix algorithm. One which also includes
the first letter in the numeric code, and one that doesn't. This module is
using the later variant.

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    http://www.k-1.com

=head1 COPYRIGHT

Text::Phonetic::Phonix is Copyright (c) 2006,2007 Maroš. Kollár.
All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO


=cut
