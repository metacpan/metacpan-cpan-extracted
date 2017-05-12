package Text::WagnerFischer::Amharic;
use base qw( Text::WagnerFischer );

use utf8;
BEGIN
{
use strict;
use vars qw( @EXPORT_OK %IMCapsMismatch $VERSION );

use Regexp::Ethiopic::Amharic ( 'getForm', 'setForm', ':forms' );

	$VERSION = "0.01";
	#
	# This linking is done so that the export of "distance" works
	# as before:
	#
	*distance = \&Text::WagnerFischer::distance;
	@EXPORT_OK = qw( distance );


	#
	# "override" the _weight function with the local one:
	#
	*Text::WagnerFischer::_weight = \&_am_weight;


	#
	# Set a new default cossts:
	#
	# WagnerFischer   :  equal, insert/delete, mismatch, 
	# Right Family but:  phoneme/glyph equiv, zemene, wrong form
	# Right Form but  :  phoneme/glyph equiv, shift slip, wrong base
	#           other :  phoneme equiv
	$Text::WagnerFischer::REFC = [0,2,3, 1,2,1, 1,1,2, 1];


	%IMCapsMismatch =(
		ስ => "ጽ",
		ጽ => "ስ",
		ቅ => "ቕ",
		ቕ => "ቅ",
		ት => "ጥ",
		ጥ => "ት",
		ች => "ጭ",
		ጭ => "ች",
		ን => "ኝ",
		ኝ => "ን",
		ክ => "ኽ",
		ኽ => "ክ",
		ዝ => "ዥ",
		ዥ => "ዝ",
		ጵ => "ፕ",
		ፕ => "ጵ"
	);
}



sub _am_weight
{
my ($x,$y,$refc)=@_;

	my $value;

	# print "Comparing: $x/$y\n";

	if ($x eq $y) {
		$value = $refc->[0];                      #  cost for letter match
	} elsif ( ($x eq '-') or ($y eq '-') ) {
		$value = $refc->[1];                      #  cost for insertion/deletion operation
	} else {
		my $yግዕዝ = setForm ( $y, $ግዕዝ );

		my $yEquiv  = Regexp::Ethiopic::Amharic::getRe ( "[=$yግዕዝ=]" );
		my $yFamily = Regexp::Ethiopic::Amharic::getRe ( "[#$yግዕዝ#]" );

		# print "  $yግዕዝ: $yEquiv / $yFamily\n";
		# print "yEquiv/yFamily:  <$yEquiv><$yFamily>\n";

		if ( $x =~ /$yFamily/ ) {                 #  x & y are in the same family
			if ( $yEquiv && $x =~ /$yEquiv/ ) {
				$value = $refc->[3];      #  phono/glyph equivalence: ኮ/ኰ, ቁ/ቍ 
			}
			elsif ( ($x =~ /[ዉው]/) && ($y =~ /[ዉው]/) ) {
				$value = $refc->[3];      #  
			}
			elsif ( (getForm($x) > 7) || (getForm($y) > 7) ) {
				$value = $refc->[4];      #  labiovelar mismatch
			}
			else {
				$value = $refc->[5];      #  form mismatch
			}
		} elsif ( getForm($x) == getForm($y) ) {  #  right form, wrong family
			if ( $yEquiv && $x =~ /$yEquiv/ ) {
				$value =  $refc->[6];     #  phono/glyph equivalence: ሳ/ሣ
			}
			else {
				my $xሳድስ = setForm ( $x, $ሳድስ );
				my $yሳድስ = setForm ( $y, $ሳድስ );
				if ( $IMCapsEquivalence{$xሳድስ} eq $yሳድስ ) {
					$value =  $refc->[7];  #  finger slipped on shift key: ት/ጥ
				}
				else {
					$value =  $refc->[8];  #  family mismatch
				}
			}
		} elsif ( $yEquiv && $x =~ /$yEquiv/ ) {  #  different family, differnt form but related: ሀ/ሐ/ኀ/ሃ/ሓ/ኃ/ኻ
			$value =  $refc->[9];             
		} else {
			$value = $refc->[2];              #  cost for letter mismatch
		}
	}

	# print "Comparing: $x/$y => $value\n";
	$value;
}


#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__



=head1 NAME

Text::WagnerFischer::Amharic - The Wagner-Fischer Algorithm for Amharic.

=head1 SYNOPSIS


  use utf8;
  use Text::WagnerFischer::Amharic qw(distance);


  print distance ( "ፀሐይ", "ጸሀይ" ), "\n";  # prints "2"

  print distance ( [0,2,3, 1,2,1, 1,1,1, 1], "ፀሐይ", "ጸሀይ" ), "\n";  # prints "2"

  my @words = ( "ፀሐይ",  "ፀሓይ", "ፀሀይ", "ፀሃይ", "ጸሐይ", "ጸሓይ", "ጸሀይ", "ጸሃይ" );

  my @distances = distance ( "ፀሐይ", @words );
  print "@distances\n"; # prints "0 1 1 1 1 2 2 2"

  @distances = distance ( [0,2,3, 1,1,1, 1,1,1, 2], "ፀሐይ", @words );
  print "@distances\n"; # prints "0 1 1 2 1 2 2 3"


=head1 DESCRIPTION

This module implements the Wagner-Fischer edit distance algorithm for
Ethiopic script under Amharic Amharic character classes.

The edit distance is a measure of the degree of proximity between two strings,
based on "edits". Each type of edit is given its own cost (weight).  In
additional to the three initial Wagner-Fischer weights, the
Amharic weight function recognizes 7 additional mismatch types:

	    / a: x = y           (cost for letter match)
 w(x,y) =  |  b: x = - or y = -  (cost for insertion/deletion operation)
	   |  c: x != y          (cost for letter mismatch)
           |  x =~ [#y#] and
           |    d: x =~ [=y=]                  (cost of decayed labiovelar)
           |    e: form(x) > 7 || form(y) > 7  (cost of labiovelar mismatch)
           |    f: else                        (cost of wrong form)
           |  form(x) == form(y) and
           |    g: x =~ [=y=]                  (cost of grapheme mismatch)
           |    h: x is a shift-slip of y      (cost of shift key mismatch)
           |    i: else                        (cost of wrong base)
           \  j: x =~ [=y=]  (cost of wrong grapheme and form, right phoneme)

These costs are given through an array reference as an option first argument
of the C<distance> subroutine (see SYNOPSIS).

When two strings have distance 0, they are the same.
Note that the distance is calculated to reach the _minimum_ cost, i.e.
choosing the most economic operation for each edit.


=head1 BUGS

None presently known.

=head1 AUTHOR

Daniel Yacob,  L<Yacob@EthiopiaOnline.Net|mailto:Yacob@EthiopiaOnline.Net>


=head1 SEE ALSO

C<Text::WagnerFischer>, C<Text::Metaphone::Amharic>, C<Regexp::Ethiopic>


=cut
