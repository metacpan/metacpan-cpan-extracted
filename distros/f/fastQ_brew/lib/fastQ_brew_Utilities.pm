#
# Utility module for fastQ_brew
#
# Please direct questions and support issues to <https://github.com/dohalloran/fastQ_brew/issues>
#
# Author: Damien O'Halloran, The George Washington University, 2017
#
# GNU GENERAL PUBLIC LICENSE
#
# POD documentation before the code

=head1 NAME

fastQ_brew_Utilities - utilities for fastQ_brew

=head2 SYNOPSIS

  use base 'Exporter';
  use Cwd;
  use List::Util qw(min max sum);


=head2 DESCRIPTION

This package provides Utility support to fastQ_brew

=head2 Support

All contributions are welcome

=head2 Reporting Bugs

Report bugs to the fastQ_brew bug tracking system to help keep track
of the bugs and their resolution. Bug reports can be submitted via the
web:
  https://github.com/dohalloran/fastQ_brew/issues

=head1 APPENDIX

The rest of the documentation details each of the object methods.

=cut

package fastQ_brew_Utilities;

use strict;
use warnings;
use List::Util qw(min max sum);
use base 'Exporter';

our @EXPORT = qw/ calcgc phred_calc prob_calc adapter_check /;

####Global Hashes
# hashes containing phred and probs
my %sanger_prob = (
    "\!"   => 1.000000000000000,
    "\“" => 0.794328234700000,
    "\#"   => 0.630957344500000,
    "\$"   => 0.501187233600000,
    "\%"   => 0.398107170600000,
    "\&"   => 0.316227766000000,
    "\'"   => 0.251188643200000,
    "\("   => 0.199526231500000,
    "\)"   => 0.158489319200000,
    "\*"   => 0.125892541200000,
    "\+"   => 0.100000000000000,
    "\,"   => 0.079432823500000,
    "\-"   => 0.063095734400000,
    "\."   => 0.050118723400000,
    "\/"   => 0.039810717100000,
    "0"    => 0.031622776600000,
    "1"    => 0.025118864300000,
    "2"    => 0.019952623100000,
    "3"    => 0.015848931900000,
    "4"    => 0.012589254100000,
    "5"    => 0.010000000000000,
    "6"    => 0.007943282300000,
    "7"    => 0.006309573400000,
    "8"    => 0.005011872300000,
    "9"    => 0.003981071700000,
    "\:"   => 0.003162277700000,
    ";"    => 0.002511886400000,
    "\<"   => 0.001995262300000,
    "\="   => 0.001584893200000,
    "\>"   => 0.001258925400000,
    "\?"   => 0.001000000000000,
    "\@"   => 0.000794328200000,
    "A"    => 0.000630957300000,
    "B"    => 0.000501187200000,
    "C"    => 0.000398107200000,
    "D"    => 0.000316227800000,
    "E"    => 0.000251188600000,
    "F"    => 0.000199526200000,
    "G"    => 0.000158489300000,
    "H"    => 0.000125892500000,
    "I"    => 0.000100000000000,
    "J"    => 0.000079432800000,
    "K"    => 0.000063095700000,
    "L"    => 0.000050118700000,
    "M"    => 0.000039810700000,
    "N"    => 0.000031622800000,
    "O"    => 0.000025118900000,
    "P"    => 0.000019952600000,
    "Q"    => 0.000015848900000,
    "R"    => 0.000012589300000,
    "S"    => 0.000010000000000,
    "T"    => 0.000007943300000,
    "U"    => 0.000006309600000,
    "V"    => 0.000005011900000,
    "W"    => 0.000003981100000,
    "X"    => 0.000003162300000,
    "Y"    => 0.000002511900000,
    "Z"    => 0.000001995300000,
    "\["   => 0.000001584900000,
    "\\"   => 0.000001258900000,
    "\]"   => 0.000001000000000,
    "\^"   => 0.000000794300000,
    "\_"   => 0.000000631000000,
    "\`"   => 0.000000501200000,
    "a"    => 0.000000398100000,
    "b"    => 0.000000316200000,
    "c"    => 0.000000251200000,
    "d"    => 0.000000199500000,
    "e"    => 0.000000158500000,
    "f"    => 0.000000125900000,
    "g"    => 0.000000100000000,
    "h"    => 0.000000079400000,
    "i"    => 0.000000063100000,
    "j"    => 0.000000050100000,
    "k"    => 0.000000039800000,
    "l"    => 0.000000031600000,
    "m"    => 0.000000025100000,
    "n"    => 0.000000020000000,
    "o"    => 0.000000015800000,
    "p"    => 0.000000012600000,
    "q"    => 0.000000010000000,
    "r"    => 0.000000007900000,
    "s"    => 0.000000006300000,
    "t"    => 0.000000005000000,
    "u"    => 0.000000004000000,
    "v"    => 0.000000003200000,
    "w"    => 0.000000002500000,
    "x"    => 0.000000002000000,
    "y"    => 0.000000001600000,
    "z"    => 0.000000001300000,
    "\{"   => 0.000000001000000,
    "\|"   => 0.000000000800000,
    "\}"   => 0.000000000600000,
    "\~"   => 0.000000000500000
);

my %sanger_phred = (
    "\!"   => 0,
    "\“" => 1,
    "\#"   => 2,
    "\$"   => 3,
    "\%"   => 4,
    "\&"   => 5,
    "\'"   => 6,
    "\("   => 7,
    "\)"   => 8,
    "\*"   => 9,
    "\+"   => 10,
    "\,"   => 11,
    "\-"   => 12,
    "\."   => 13,
    "\/"   => 14,
    "0"    => 15,
    "1"    => 16,
    "2"    => 17,
    "3"    => 18,
    "4"    => 19,
    "5"    => 20,
    "6"    => 21,
    "7"    => 22,
    "8"    => 23,
    "9"    => 24,
    "\:"   => 25,
    ";"    => 26,
    "\<"   => 27,
    "\="   => 28,
    "\>"   => 29,
    "\?"   => 30,
    "\@"   => 31,
    "A"    => 32,
    "B"    => 33,
    "C"    => 34,
    "D"    => 35,
    "E"    => 36,
    "F"    => 37,
    "G"    => 38,
    "H"    => 39,
    "I"    => 40,
    "J"    => 41,
    "K"    => 42,
    "L"    => 43,
    "M"    => 44,
    "N"    => 45,
    "O"    => 46,
    "P"    => 47,
    "Q"    => 48,
    "R"    => 49,
    "S"    => 50,
    "T"    => 51,
    "U"    => 52,
    "V"    => 53,
    "W"    => 54,
    "X"    => 55,
    "Y"    => 56,
    "Z"    => 57,
    "\["   => 58,
    "\\"   => 59,
    "\]"   => 60,
    "\^"   => 61,
    "\_"   => 62,
    "\`"   => 63,
    "a"    => 64,
    "b"    => 65,
    "c"    => 66,
    "d"    => 67,
    "e"    => 68,
    "f"    => 69,
    "g"    => 70,
    "h"    => 71,
    "i"    => 72,
    "j"    => 73,
    "k"    => 74,
    "l"    => 75,
    "m"    => 76,
    "n"    => 77,
    "o"    => 78,
    "p"    => 79,
    "q"    => 80,
    "r"    => 81,
    "s"    => 82,
    "t"    => 83,
    "u"    => 84,
    "v"    => 85,
    "w"    => 86,
    "x"    => 87,
    "y"    => 88,
    "z"    => 89,
    "\{"   => 90,
    "\|"   => 91,
    "\}"   => 92,
    "\~"   => 93
);

my %illumina_prob = (
    "@"  => 1.000000000000000,
    "A"  => 0.794328234700000,
    "B"  => 0.630957344500000,
    "C"  => 0.501187233600000,
    "D"  => 0.398107170600000,
    "E"  => 0.316227766000000,
    "F"  => 0.251188643200000,
    "G"  => 0.199526231500000,
    "H"  => 0.158489319200000,
    "I"  => 0.125892541200000,
    "J"  => 0.100000000000000,
    "K"  => 0.079432823500000,
    "L"  => 0.063095734400000,
    "M"  => 0.050118723400000,
    "N"  => 0.039810717100000,
    "O"  => 0.031622776600000,
    "P"  => 0.025118864300000,
    "Q"  => 0.019952623100000,
    "R"  => 0.015848931900000,
    "S"  => 0.012589254100000,
    "T"  => 0.010000000000000,
    "U"  => 0.007943282300000,
    "V"  => 0.006309573400000,
    "W"  => 0.005011872300000,
    "X"  => 0.003981071700000,
    "Y"  => 0.003162277700000,
    "Z"  => 0.002511886400000,
    "["  => 0.001995262300000,
    "\\" => 0.001584893200000,
    "]"  => 0.001258925400000,
    "\^" => 0.001000000000000,
    "\_" => 0.000794328200000,
    "\`" => 0.000630957300000,
    "a"  => 0.000501187200000,
    "b"  => 0.000398107200000,
    "c"  => 0.000316227800000,
    "d"  => 0.000251188600000,
    "e"  => 0.000199526200000,
    "f"  => 0.000158489300000,
    "g"  => 0.000125892500000,
    "h"  => 0.000100000000000,
    "i"  => 0.000079432800000,
    "j"  => 0.000063095700000,
    "k"  => 0.000050118700000,
    "l"  => 0.000039810700000,
    "m"  => 0.000031622800000,
    "n"  => 0.000025118900000,
    "o"  => 0.000019952600000,
    "p"  => 0.000015848900000,
    "q"  => 0.000012589300000,
    "r"  => 0.000010000000000,
    "s"  => 0.000007943300000,
    "t"  => 0.000006309600000,
    "u"  => 0.000005011900000,
    "v"  => 0.000003981100000,
    "w"  => 0.000003162300000,
    "x"  => 0.000002511900000,
    "y"  => 0.000001995300000,
    "z"  => 0.000001584900000,
    "{"  => 0.000001258900000,
    "|"  => 0.000001000000000,
    "}"  => 0.000000794300000,
    "~"  => 0.000000631000000
);

my %illumina_phred = (
    "@"  => 0,
    "A"  => 1,
    "B"  => 2,
    "C"  => 3,
    "D"  => 4,
    "E"  => 5,
    "F"  => 6,
    "G"  => 7,
    "H"  => 8,
    "I"  => 9,
    "J"  => 10,
    "K"  => 11,
    "L"  => 12,
    "M"  => 13,
    "N"  => 14,
    "O"  => 15,
    "P"  => 16,
    "Q"  => 17,
    "R"  => 18,
    "S"  => 19,
    "T"  => 20,
    "U"  => 21,
    "V"  => 22,
    "W"  => 23,
    "X"  => 24,
    "Y"  => 25,
    "Z"  => 26,
    "["  => 27,
    "\\" => 28,
    "]"  => 29,
    "\^" => 30,
    "\_" => 31,
    "\`" => 32,
    "a"  => 33,
    "b"  => 34,
    "c"  => 35,
    "d"  => 36,
    "e"  => 37,
    "f"  => 38,
    "g"  => 39,
    "h"  => 40,
    "i"  => 41,
    "j"  => 42,
    "k"  => 43,
    "l"  => 44,
    "m"  => 45,
    "n"  => 46,
    "o"  => 47,
    "p"  => 48,
    "q"  => 49,
    "r"  => 50,
    "s"  => 51,
    "t"  => 52,
    "u"  => 53,
    "v"  => 54,
    "w"  => 55,
    "x"  => 56,
    "y"  => 57,
    "z"  => 58,
    "{"  => 59,
    "|"  => 60,
    "}"  => 61,
    "~"  => 62
);

####################################
####################################

=head1 calcgc

 Title   :  calcgc
 Usage   :  $Tm = calcgc( $read );
 Function:  calculates read GC%
 Returns :  GC%
 
=cut

sub calcgc {
    my $seq   = $_[0];
    my $count = 0;
    my $len   = length($seq);
    for ( my $i = 1 ; $i < $len + 1 ; $i++ ) {
        my $base = substr $seq, $i, 1;
        $count++ if $base =~ /[G|C]/i;
    }
    my $num = ( $count / $len ) * 100;
    return $num;
}

####################################

=head1 phred_calc

 Title   :  phred_calc
 Usage   :  $Tm = phred_calc( $read, $lib );
 Function:  calculates phred score for each read
 Returns :  read phred score
 
=cut

sub phred_calc {
    my $seq   = $_[0];
    my $lib   = $_[1];
    my $score = 0;
    my $len   = length($seq);
    my $i;

    # Compute phred score from hash
    for ( $i = 0 ; $i < $len - 1 ; $i++ ) {
        my $base = substr $seq, $i, 1;
        if ( $lib eq "sanger" ) {
            $score += $sanger_phred{$base};
        }
        elsif ( $lib eq "illumina" ) {
            $score += $illumina_phred{$base};
        }
    }
    return $score;
}

####################################

=head1 prob_calc

 Title   :  prob_calc
 Usage   :  prob_calc( $read, $lib );
 Function:  calculates error probability for each read
 Returns :  probability
 
=cut

sub prob_calc {
    my $seq   = $_[0];
    my $lib   = $_[1];
    my $score = 0;
    my $len   = length($seq);
    my $i;

    # Compute prob score from hash
    for ( $i = 0 ; $i < $len - 1 ; $i++ ) {
        my $base = substr $seq, $i, 1;
        if ( $lib eq "sanger" ) {
            $score += $sanger_prob{$base};
        }
        elsif ( $lib eq "illumina" ) {
            $score += $illumina_prob{$base};
        }
    }
    return $score;
}

####################################

=head1 adapter_check

 Title   :  adapter_check
 Usage   :  adapter_check( $read, $adapter, $mismatches );
 Function:  searches for matches that permit number of mismatches and removes macthes from reads
 Returns :  fastQ file without adapters
 
=cut

sub adapter_check {
    my $specificty = shift;
    my $pattern    = shift;
    my $mis        = shift;

    my $mis_mismatch = mismatch_pattern( $pattern, $mis );
    my @approximate_matches = match_positions( $mis_mismatch, $specificty );
    my $number_matches = @approximate_matches;

    return $number_matches;

    use re qw(eval);
    use vars qw($matchStart);

    sub match_positions {
        my $pattern;
        local $_;
        ( $pattern, $_ ) = @_;
        my @results;
        local $matchStart;
        my $instrumentedPattern = qr/(?{ $matchStart = pos() })$pattern/;
        while (/$instrumentedPattern/g) {
            my $nextStart = pos();
            push @results, "[$matchStart..$nextStart)";
            pos() = $matchStart + 1;
        }
        return @results;
    }

    sub mismatch_pattern {
        my ( $original_pattern, $mismatches_allowed ) = @_;
        $mismatches_allowed >= 0
          or die "Number of mismatches must be greater than or equal to zero\n";
        my $new_pattern =
          make_approximate( $original_pattern, $mismatches_allowed );
        return qr/$new_pattern/;
    }

    sub make_approximate {
        my ( $pattern, $mismatches_allowed ) = @_;
        if ( $mismatches_allowed == 0 ) { return $pattern }
        elsif ( length($pattern) <= $mismatches_allowed ) {
            $pattern =~ tr/ACTG/./;
            return $pattern;
        }
        else {
            my ( $first, $rest ) = $pattern =~ /^(.)(.*)/;
            my $after_match = make_approximate( $rest, $mismatches_allowed );
            if ( $first =~ /[ACGT]/ ) {
                my $after_miss =
                  make_approximate( $rest, $mismatches_allowed - 1 );
                return "(?:$first$after_match|.$after_miss)";
            }
            else { return "$first$after_match" }
        }
    }
}

####################################
####################################

1;
