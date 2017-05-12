package Text::TEI::Collate::Diff;

use strict;
use warnings;

# This code is pretty much all taken from Algorithm::Diff, and hacked up to
# support non-exact matching in the diff comparison and to remove all the bits
# of the original that I don't use.	I would have liked to do this via
# subclassing / extension but it was not feasible.

use integer;    # see below in _replaceNextLargerWith() for mod to make
                # if you don't use this

# McIlroy-Hunt diff algorithm
# Adapted from the Smalltalk code of Mario I. Wolczko, <mario@wolczko.com>
# by Ned Konz, perl@bike-nomad.com
# Updates by Tye McQueen, http://perlmonks.org/?node=tye

=begin testing

use lib 'lib';
use Test::More::UTF8;
use Text::TEI::Collate;
my @mss;
my $aligner = Text::TEI::Collate->new();
push( @mss, $aligner->read_source( 'Արդ ահա մինչև ցայս վայրս բազմաջան զհարիւրից ամացն զորս բազում' ) );
push( @mss, $aligner->read_source( 'Արդ մինչև ցայս վայրս բազմեջան զ100ից ամաց զօրս ի բազում' ) );
$aligner->make_fuzzy_matches( $mss[0]->words, $mss[1]->words );
my $diff = Text::TEI::Collate::Diff->new( $mss[0]->words, $mss[1]->words, $aligner );
# First chunk should be Same, length 1
my $pos = $diff->Next();
ok( $pos );
ok( $diff->Same, "first chunk same" );
is( scalar $diff->Items(1), 1, "first chunk has 1 item ");
# Second chunk should be Del, length 1
$pos = $diff->Next();
ok( $pos );
is( scalar $diff->Items(1), 1, "second chunk has 1 base" );
is( scalar $diff->Items(2), 0, "second chunk has 0 new" );
# Third chunk should be Same, length 4
$pos = $diff->Next();
ok( $pos );
ok( $diff->Same, "third chunk same" );
is( scalar $diff->Items(1), 4, "third chunk has 4 items" );
# Fourth chunk should be Different, length 1
$pos = $diff->Next();
ok( $pos );
ok( !$diff->Same, "fourth chunk different" );
is( scalar $diff->Items(1), 1, "fourth chunk has 1 base " );
is( scalar $diff->Items(2), 1, "fourth chunk has 1 new" );
# Fifth chunk should be Same, length 2
$pos = $diff->Next();
ok( $pos );
ok( $diff->Same, "fifth chunk same" );
is( scalar $diff->Items(1), 2, "fifth chunk has 2 items ");
# Sixth chunk should be Add, length 1
$pos = $diff->Next();
ok( $pos );
is( scalar $diff->Items(1), 0, "sixth chunk has 0 base" );
is( scalar $diff->Items(2), 1, "sixth chunk has 1 new" );
# Seventh chunk should be Same, length 1
$pos = $diff->Next();
ok( $pos );
ok( $diff->Same, "seventh chunk same" );
is( scalar $diff->Items(1), 1, "seventh chunk has 1 item" );
# No more chunks
$pos = $diff->Next;
ok( !$pos );

=end testing

=cut

# Create a hash that maps each element of $aCollection to the set of
# positions it occupies in $aCollection, restricted to the elements
# within the range of indexes specified by $start and $end.
# The fourth parameter is a subroutine reference that will be called to
# generate a string to use as a key.
# Additional parameters, if any, will be passed to this subroutine.
#
# my $hashRef = _withPositionsOfInInterval( \@array, $start, $end, $keyGen );

sub _withPositionsOfInInterval # mark
{
    my $aCollection = shift;    # array ref
    my $start       = shift;
    my $end         = shift;
    my $keyGen      = shift;
    my %d;
    my $index;
    for ( $index = $start ; $index <= $end ; $index++ )
    {
        my $element = $aCollection->[$index];
        my $key = &$keyGen( $element );
        if ( exists( $d{$key} ) )
        {
            unshift ( @{ $d{$key} }, $index );
        }
        else
        {
            $d{$key} = [$index];
        }
    }
    return wantarray ? %d : \%d;
}

# Find the place at which aValue would normally be inserted into the
# array. If that place is already occupied by aValue, do nothing, and
# return undef. If the place does not exist (i.e., it is off the end of
# the array), add it to the end, otherwise replace the element at that
# point with aValue.  It is assumed that the array's values are numeric.
# This is where the bulk (75%) of the time is spent in this module, so
# try to make it fast!

sub _replaceNextLargerWith  # mark
{
    my ( $array, $aValue, $high ) = @_;
    $high ||= $#$array;

    # off the end?
    if ( $high == -1 || $aValue > $array->[-1] )
    {
        push ( @$array, $aValue );
        return $high + 1;
    }

    # binary search for insertion point...
    my $low = 0;
    my $index;
    my $found;
    while ( $low <= $high )
    {
        $index = ( $high + $low ) / 2;

        # $index = int(( $high + $low ) / 2);  # without 'use integer'
        $found = $array->[$index];

        if ( $aValue == $found )
        {
            return undef;
        }
        elsif ( $aValue > $found )
        {
            $low = $index + 1;
        }
        else
        {
            $high = $index - 1;
        }
    }

    # now insertion point is in $low.
    $array->[$low] = $aValue;    # overwrite next larger
    return $low;
}

# This method computes the longest common subsequence in $a and $b.

# Result is array or ref, whose contents is such that
#   $a->[ $i ] == $b->[ $result[ $i ] ]
# foreach $i in ( 0 .. $#result ) if $result[ $i ] is defined.

# An additional argument may be passed; this is a hash or key generating
# function that should return a string that uniquely identifies the given
# element.  It should be the case that if the key is the same, the elements
# will compare the same. If this parameter is undef or missing, the key
# will be the element as a string.

# By default, comparisons will use "eq" and elements will be turned into keys
# using the default stringizing operator '""'.

# Additional parameters, if any, will be passed to the key generation
# routine.

sub _longestCommonSubsequence # mark
{
    my $a        = shift;    # array ref or hash ref
    my $b        = shift;    # array ref or hash ref
	my $collator = shift;

    # Check for bogus (non-ref) argument values
    if ( !ref($a) || !ref($b) )
    {
        my @callerInfo = caller(1);
        die 'error: must pass array references to ' . $callerInfo[3];
    }

	my $keyGen = sub { $collator->diff_key( @_ ) };
    my $compare = sub {
		my( $a, $b ) = @_;
        &$keyGen( $a ) eq &$keyGen( $b );
       };

    my ( $aStart, $aFinish, $matchVector ) = ( 0, $#$a, [] );

	my ( $bStart, $bFinish, $bMatches ) = ( 0, $#$b, {} );

	# First we prune off any common elements at the beginning
  	while ( $aStart <= $aFinish
      	and $bStart <= $bFinish
      	and &$compare( $a->[$aStart], $b->[$bStart] ) ) {
		$matchVector->[ $aStart++ ] = $bStart++;
 	}

 	# ...and at the end
 	while ( $aStart <= $aFinish
		and $bStart <= $bFinish
		and &$compare( $a->[$aFinish], $b->[$bFinish] ) ) {
		$matchVector->[ $aFinish-- ] = $bFinish--;
	}

	# Now compute the equivalence classes of positions of elements
 	$bMatches = _withPositionsOfInInterval( $b, $bStart, $bFinish, $keyGen );
 	my $thresh = [];
 	my $links  = [];

 	my ( $i, $ai, $j, $k );
	for ( $i = $aStart ; $i <= $aFinish ; $i++ ) {
 		$ai = &$keyGen( $a->[$i], @_ );
 		if ( exists( $bMatches->{$ai} ) ) {
			$k = 0;
			for $j ( @{ $bMatches->{$ai} } ) {
				# optimization: most of the time this will be true
				if ( $k and $thresh->[$k] > $j and $thresh->[ $k - 1 ] < $j ) {
 					$thresh->[$k] = $j;
  				} else {
 					$k = _replaceNextLargerWith( $thresh, $j, $k );
				}

				# oddly, it's faster to always test this (CPU cache?).
				if ( defined($k) ) {
					$links->[$k] = [ ( $k ? $links->[ $k - 1 ] : undef ), $i, $j ];
				}
			}
		}
	}

 	if (@$thresh) {
		for ( my $link = $links->[$#$thresh] ; $link ; $link = $link->[0] ) {
			$matchVector->[ $link->[1] ] = $link->[2];
 		}
 	} 
	return wantarray ? @$matchVector : $matchVector;
}

sub LCSidx #mark
{
    my $a= shift @_;
    my $b= shift @_;
    my $match= _longestCommonSubsequence( $a, $b, @_ );
    my @am= grep defined $match->[$_], 0..$#$match;
    my @bm= @{$match}[@am];
    return \@am, \@bm;
}

sub compact_diff #mark
{
    my $a= shift @_;
    my $b= shift @_;
    my( $am, $bm )= LCSidx( $a, $b, @_ );
    my @cdiff;
    my( $ai, $bi )= ( 0, 0 );
    push @cdiff, $ai, $bi;
    while( 1 ) {
        while(  @$am  &&  $ai == $am->[0]  &&  $bi == $bm->[0]  ) {
            shift @$am;
            shift @$bm;
            ++$ai, ++$bi;
        }
        push @cdiff, $ai, $bi;
        last   if  ! @$am;
        $ai = $am->[0];
        $bi = $bm->[0];
        push @cdiff, $ai, $bi;
    }
    push @cdiff, 0+@$a, 0+@$b
        if  $ai < @$a || $bi < @$b;
    return wantarray ? @cdiff : \@cdiff;
}

########################################
sub _Idx()  { 0 } # $me->[_Idx]: Ref to array of hunk indices
            # 1   # $me->[1]: Ref to first sequence
            # 2   # $me->[2]: Ref to second sequence
sub _End()  { 3 } # $me->[_End]: Diff between forward and reverse pos
sub _Same() { 4 } # $me->[_Same]: 1 if pos 1 contains unchanged items
sub _Base() { 5 } # $me->[_Base]: Added to range's min and max
sub _Pos()  { 6 } # $me->[_Pos]: Which hunk is currently selected
sub _Off()  { 7 } # $me->[_Off]: Offset into _Idx for current position
sub _Min() { -2 } # Added to _Off to get min instead of max+1

sub Die
{
    require Carp;
    Carp::confess( @_ );
}

sub _ChkPos #mark
{
    my( $me )= @_;
    return   if  $me->[_Pos];
    my $meth= ( caller(1) )[3];
    Die( "Called $meth on 'reset' object" );
}

sub _ChkSeq #mark
{
    my( $me, $seq )= @_;
    return $seq + $me->[_Off]
        if  1 == $seq  ||  2 == $seq;
    my $meth= ( caller(1) )[3];
    Die( "$meth: Invalid sequence number ($seq); must be 1 or 2" );
}

sub new #mark
{
    my( $us, $seq1, $seq2, $collator ) = @_;

    my $cdif= compact_diff( $seq1, $seq2, $collator );
    my $same= 1;
    if(  0 == $cdif->[2]  &&  0 == $cdif->[3]  ) {
        $same= 0;
        splice @$cdif, 0, 2;
    }
    my @obj= ( $cdif, $seq1, $seq2 );
    $obj[_End] = (1+@$cdif)/2;
    $obj[_Same] = $same;
    $obj[_Base] = 0;
    my $me = bless \@obj, $us;
    $me->Reset( 0 );
    return $me;
}

sub Reset #mark
{
    my( $me, $pos )= @_;
    $pos= int( $pos || 0 );
    $pos += $me->[_End]
        if  $pos < 0;
    $pos= 0
        if  $pos < 0  ||  $me->[_End] <= $pos;
    $me->[_Pos]= $pos || !1;
    $me->[_Off]= 2*$pos - 1;
    return $me;
}


sub Next { #mark
    my( $me, $steps )= @_;
    $steps= 1   if  ! defined $steps;
    if( $steps ) {
        my $pos= $me->[_Pos];
        my $new= $pos + $steps;
        $new= 0   if  $pos  &&  $new < 0;
        $me->Reset( $new )
    }
    return $me->[_Pos];
}


sub Range { #mark
    my( $me, $seq, $base )= @_;
    $me->_ChkPos();
    my $off = $me->_ChkSeq($seq);
    if( !wantarray ) {
        return  $me->[_Idx][ $off ]
            -   $me->[_Idx][ $off + _Min ];
    }
    $base= $me->[_Base] if !defined $base;
    return  ( $base + $me->[_Idx][ $off + _Min ] )
        ..  ( $base + $me->[_Idx][ $off ] - 1 );
}

sub Items { #mark
    my( $me, $seq )= @_;
    $me->_ChkPos();
    my $off = $me->_ChkSeq($seq);
    if( !wantarray ) {
        return  $me->[_Idx][ $off ]
            -   $me->[_Idx][ $off + _Min ];
    }
    return
        @{$me->[$seq]}[
                $me->[_Idx][ $off + _Min ]
            ..  ( $me->[_Idx][ $off ] - 1 )
        ];
}

sub Same { #mark
    my( $me )= @_;
    $me->_ChkPos();
    return wantarray ? () : 0
        if  $me->[_Same] != ( 1 & $me->[_Pos] );
    return $me->Items(1);
}


1;
