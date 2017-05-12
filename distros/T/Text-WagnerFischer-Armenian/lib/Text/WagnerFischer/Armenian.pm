package Text::WagnerFischer::Armenian;

=encoding utf8

=head1 NAME

Text::WagnerFischer::Armenian - a variation on Text::WagnerFischer for Armenian-language strings

=head1 SYNOPSIS

 use Text::WagnerFischer::Armenian qw( distance );
 use utf8;  # for the Armenian characters in the source code

 print distance("ձեռն", "ձեռան") . "\n";  
    # "dzerrn -> dzerran"; prints 1
 print distance("ձեռն", "ձերն") . "\n";  
    # "dzerrn -> dzern"; prints 0.5
 print distance("կինք", "կին") . "\n";
    # "kin" -> "kink'"; prints 0.5
 my @words = qw( զօրսն Զորս զզօրսն );
 my @distances = distance( "զօրս", @words );
 print "@distances\n";
    # "zors" -> "zorsn, Zors, zzorsn" 
    # prints "0.5 0.25 1"

 # Change the cost of a letter case mismatch to 1
 my $edit_values = [ 0, 1, 1, 1, 0.5, 0.5, 0.5 ],  
 print distance( $edit_values, "ձեռն", "Ձեռն" ) . "\n";
    # "dzerrn" -> "DZerrn"; prints 1

=head1 DESCRIPTION

This module implements the Wagner-Fischer distance algorithm modified
for Armenian strings.  The Armenian language has a number of
single-letter prefixes and suffixes which, while not changing the
basic meaning of the word, function as definite articles,
prepositions, or grammatical markers.  These changes, and letter
substitutions that represent vocalic equivalence, should be counted as
a smaller edit distance than a change that is a normal character
substitution.

The Armenian weight function recognizes four extra edit types:

            / a: x = y           (cost for letter match)
            | b: x = - or y = -  (cost for letter insertion/deletion)
w( x, y ) = | c: x != y          (cost for letter mismatch) 
            | d: x = X           (cost for case mismatch)
            | e: x ~ y           (cost for letter vocalic equivalence)
            | f: x = (z|y|ts) && y = - (or vice versa)
            |          (cost for grammatic prefix)
            | g: x = (n|k'|s|d) && y = - (or vice versa)
            \          (cost for grammatic suffix)


=cut

use strict;
use warnings;
no warnings 'redefine';
use Exporter 'import';
use Text::WagnerFischer;
use utf8;

my( %VocalicEquivalence, @Prefixes, @Suffixes, $REFC );

our $VERSION = "0.04";
our @EXPORT_OK = qw( &distance &am_lc );

# Set new default costs:
#
# WagnerFischer   :  equal, insert/delete, mismatch, 
# LetterCaseEquiv :  same word, case mismatch
# VocalicEquiv    :  letter that changed with pronunciation shift
# PrefixAddDrop   :  same word, one has prefix e.g. preposition form "y-"
# SuffixAddDrop   :  same word, one has suffix e.g. definite article "-n"
$REFC = [ 0, 1, 1,  0.25, 0.5, 0.5, 0.5 ];   # mid-word: no pre/suffix

%VocalicEquivalence = (
    'բ' => [ 'պ' ],
    'գ' => [ 'ք', 'կ' ],
    'դ' => [ 'տ' ],
    'ե' => [ 'է' ],
    'է' => [ 'ե' ],
    'թ' => [ 'տ' ],
    'լ' => [ 'ղ' ],
    'կ' => [ 'գ', 'ք' ],
    'ղ' => [ 'լ' ],
    'յ' => [ '՛' ],      # Only in manuscripts
    'ո' => [ 'օ' ],
    'պ' => [ 'բ', 'փ' ],
    'ռ' => [ 'ր' ],
    'վ' => [ 'ւ' ],
    'տ' => [ 'դ', 'թ'],
    'ր' => [ 'ռ' ],
    'ւ' => [ 'վ' ],
    'փ' => [ 'պ', 'ֆ' ],
    'ք' => [ 'գ', 'կ' ],
    'օ' => [ 'ո' ],
    'ֆ' => [ 'փ' ],
    '՛' => [ 'յ' ],      # Only in manuscripts
    );

@Prefixes = qw( զ ց յ );
@Suffixes = qw( ն ս դ ք );

sub _am_weight
{
    my ($x,$y,$refc)=@_;

    if ($x eq $y) {
	# Simple case: exact match.
	return $refc->[0];
    } elsif( am_lc( $x ) eq am_lc( $y ) ) {
	# Almost as simple: case difference.
	return $refc->[3];   # Vocalic equivalence.
    }

    # Got this far?  We have to play games with prefixes, suffixes,
    # similar-letter substitution, and the like.

    # Downcase both of them.
    $x = am_lc( $x );
    $y = am_lc( $y );

    if ( ($x eq '-') or ($y eq '-') ) {
	# Are we dealing with a prefix or a suffix?
	# print STDERR "x is $x; y is $y;\n";
	if( grep( /(\Q$x\E|\Q$y\E)/, @Prefixes ) > 0 ) {
	    return $refc->[5];
	} elsif( grep( /(\Q$x\E|\Q$y\E)/, @Suffixes ) > 0 ) {
	    return $refc->[6];
	} else {
	    # Normal insert/delete
	    return $refc->[1];
	}
    } else {
	if( exists( $VocalicEquivalence{$x} ) ) {
	    # Same word, vocalic shift?
	    # N.B. This will mistakenly give less weight to a few genuinely
	    # different words, e.g. the verbs "գամ" vs. "կամ".  I can live with that.
	    my @equivs = @{$VocalicEquivalence{$x}};
	    my $val = grep (/$y/, @equivs ) ? $refc->[4] : $refc->[2];
	    return $val;
	} else {
	    return $refc->[2];
	}
    }
}

# Annoyingly, I need to copy this whole damn thing because I need to change
# the refc mid-stream.

=head1 SUBROUTINES

=over 

=item B<distance>( \@editweight, $string1, $string2, [ .. $stringN ] );

=item B<distance>( $string1, $string2, [ .. $stringN ] );

The main exported function of this module.  Takes a list of two or
more strings and returns the edit distance between the first string
and each of the others.  The "edit_distances" array is an optional
first argument, with which users may override the default edit
penalties, as described above.

=cut

sub distance {
    my ($refcarg,$s,@t)=@_;

    # The refc values are as documented above:
    # 0. x,x; 1. x,''; 2. x,y; 3. x,X; 4. d,t; 5. x,zx; 6. x,xn
    # 6 only applies at beginnings of words, and 7 only applies at
    # ends.

    my $refc = [];
    if (!@t) {
	# Two args...
	if (ref($refcarg) ne "ARRAY") {
	    # the first of which is a string...
	    if (ref($s) ne "ARRAY") {
		# ...and the second of which is a string.
		# Use default refc set.
		$t[0]=$s;
		$s=$refcarg;
		push( @$refc, @$REFC );
	    } else {
		# ...one of which is an array.  Croak.
		require Carp;
		Carp::croak("Text::WagnerFischer: second string is needed");
	    }
	} else {
	    # one refc, and one string.  Croak.
	    require Carp;
	    Carp::croak("Text::WagnerFischer: second string is needed");
	}
    } elsif (ref($refcarg) ne "ARRAY") {
	# Three or more args, all strings.
	# Use default refc set.
	unshift @t,$s;
	$s=$refcarg;
	push( @$refc, @$REFC );
    } else {
	# A refc array and (presumably) some strings.
	# Copy the passed array into our own array, because
	# we are going to mutate our copy.
	push( @$refc, @$refcarg );
    }    
    
    # Set up the refc arrays in three different formats - one for word
    # beginnings, one for word ends, and one for everything else.
    my( $refc_start, $refc_end ) = ( [], [] );
    push( @$refc_start, @$refc );
    # Count suffixes as normal add/del.
    $refc_start->[6] = $refc->[1];
    push( @$refc_end, @$refc );
    $refc_end->[5] = $refc->[1];

    # Now alter our main refc, which should no longer
    # care about prefixes or suffixes.
    $refc->[5] = $refc->[1];
    $refc->[6] = $refc->[1];
	

    # binmode STDERR, ":utf8"; # for debugging
    # Start the real string comparison.
    my $n=length($s);
    my @result;
    
    foreach my $t (@t) {
	
	my @d;
	
	my $m=length($t);
	if(!$n) {push @result,$m*$refc->[1];next}
	if(!$m) {push @result,$n*$refc->[1];next}
	
	$d[0][0]=0;
	
	# Populate the zero row.
	# Cannot assume that blank vs. 1st letter is "add".  Might
	# be "prefix."
	my $f_i = substr($s,0,1);
	foreach my $i (1 .. $n) {$d[$i][0]=$i*&_am_weight('-',$f_i,$refc_start);}
	my $f_j = substr($t,0,1);
	foreach my $j (1 .. $m) {$d[0][$j]=$j*&_am_weight($f_j,'-',$refc_start);}
	
	foreach my $i (1 .. $n) {
	    my $s_i=substr($s,$i-1,1);
	    foreach my $j (1 .. $m) {
		# Switch to suffix refc if we are to end of either word.
		$refc = $refc_end if( $i == $n || $j == $m );
		my $t_i=substr($t,$j-1,1);
		
		$d[$i][$j]=Text::WagnerFischer::_min($d[$i-1][$j]+_am_weight($s_i,'-',$refc),
				$d[$i][$j-1]+_am_weight('-',$t_i,$refc),
				$d[$i-1][$j-1]+_am_weight($s_i,$t_i,$refc));
	    }
	}
	
	my $r = $d[$n][$m];
	## Round up to get an integer result.
	## On second thought, don't.
	# if( $r - int( $r ) > 0 ) {
	#     $r = int( $r ) + 1;
	# }

	push @result, $r;

	## Debugging statements
	# print "\nARRAY for $s / $t\n";
	# foreach my $arr ( @d ) {
	#     print join( " ", @$arr ) . "\n"
	# }
    }
    if (wantarray) {return @result} else {return $result[0]}
}
  

=item B<am_lc>( $char )

A small utility function, useful for Armenian text.  Returns the
lowercase version of the character passed in.

=back

=cut

sub am_lc {
    my $char = shift;
    # Is it in the uppercase Armenian range?
    if( $char =~ /[\x{531}-\x{556}]/ ) {
	my $codepoint = unpack( "U", $char );
	$codepoint += 48;
	$char = pack( "U", $codepoint );
    }
    return $char;
}

=head1 LIMITATIONS

There are many cases of Armenian word equivalence that are not
perfectly handled by this; it is meant to be a rough heuristic for
comparing transcriptions of handwriting.  In particular, multi-letter
suffixes, and some orthographic equivalence e.g "o" -> "aw", are not
handled at all.

=head1 LICENSE

This package is free software and is provided "as is" without express
or implied warranty.  You can redistribute it and/or modify it under 
the same terms as Perl itself.

=head1 AUTHOR

Tara L Andrews, L<aurum@cpan.org>

=cut

1;
