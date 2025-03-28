package Text::TransMetaphone::en_US;
use utf8;

BEGIN
{
	use strict;
	use warnings;
	use vars qw( $VERSION $LocaleRange );

	$VERSION = '0.10';

	$LocaleRange = qr/\p{InBasicLatin}/;
}


my($primary,$secondary) = ("","");
my $KEY_LIMIT = 4;

sub appendPhones
{
	$primary   .= $_[0];
	$secondary .= ( $_[1] ) ? $_[1] : $_[0];
}

sub stringAt
{
my($word,$start,$length) = (shift,shift,shift);

	return 0 if(  (0 > $start) || ($start >= length($word) ) );

	my $sub = substr( $word, $start, $length );

	foreach my $test ( @_ ) {
	      return 1 if(  $sub eq $test );
	}

}

sub charAt
{
	      # string , index
	substr( $_[0], $_[1], 1 );
}

sub isVowel
{
	      # string , index
	substr( $_[0], $_[1], 1 ) =~ /[AEIOUY]/ ;
}

sub SlavoGermanic
{
	$_ = shift;

	return ( /([KW])|(CZ)|(WITZ)/ ) ? 1 : 0 ;
}

#
# Note that the code below is converted from the C language
# and may still exhibit C language style and logic.
#
sub trans_metaphone
{
	my ($original) = uc( $_[0] );

	my $length = length($original);
    	my $last = $length - 1; 
	my $current = 0;


	#  Initial 'X' is pronounced 'Z' e.g. 'Xavier'
	if( charAt($original, 0) eq 'X' ) {
		appendPhones( "s" );   # 'Z' maps to 'S'
		$current   += 1;
	}


	while ( ($KEY_LIMIT < length($primary))  || (length($secondary) < $KEY_LIMIT) ) {

		next if( $current >= $length);

		my $ch =  charAt($original, $current);
	    	if( $ch =~ /[AEIOUY]/ ) {
			if( $current == 0) {
				# all init vowels now map to 'A'
				appendPhones( "a" );
			}
			$current += 1;
		}
		elsif( $ch eq 'B' ) {
			# "-mb", e.g", "dumb", already skipped over...
			appendPhones( "p" );

			$current += ( charAt($original, ($current + 1)) eq 'B' )
				 ? 2
				 : 1
			;
		}
		elsif( $ch eq 'Ç' ) {
			appendPhones( "s" );
			$current += 1;
		}
		elsif( $ch eq 'C' ) {
			# various germanic
			if( ($current > 1)
			    && !isVowel($original, $current - 2)
			    && stringAt($original, ($current - 1), 3, "ACH", "")
			    && ((charAt($original, $current + 2) != 'I')
			    && ((charAt($original, $current + 2) != 'E')
			    || stringAt($original, ($current - 2), 6, "BACHER", "MACHER", ""))))
			{
				appendPhones( "k" );
				$current += 2;
			}

			# special case 'caesar'
			if( ($current == 0) && stringAt($original, $current, 6, "CAESAR", "")) {
				appendPhones( "s" );
				$current += 2;
			}

			# italian 'chianti'
			if( stringAt($original, $current, 4, "CHIA", "")) {
				appendPhones( "k" );
				$current += 2;
			}

			if( stringAt($original, $current, 2, "CH", "")) {
				# find 'michael'
				if( ($current > 0) && stringAt($original, $current, 4, "CHAE", "")) {
					appendPhones( "k", "ʃ" );
					$current += 2;
				}
	
				# greek roots e.g. 'chemistry', 'chorus'
				if( ($current == 0)
				   && (stringAt($original, ($current + 1), 5, "HARAC", "HARIS", "")
				   || stringAt($original, ($current + 1), 3, "HOR", "HYM", "HIA", "HEM", ""))
				   && !stringAt($original, 0, 5, "CHORE", ""))
				{
					appendPhones( "k" );
					$current += 2;
					next;
				}

				# germanic, greek, or otherwise 'ch' for 'kh' sound
				if(  (stringAt($original, 0, 4, "VAN ", "VON ", "")
				   || stringAt($original, 0, 3, "SCH", ""))
				      #  'architect but not 'arch', 'orchestra', 'orchid'
				   || stringAt($original, ($current - 2), 6, "ORCHES", "ARCHIT", "ORCHID", "")
				   || stringAt($original, ($current + 2), 1, "T", "S", "")
				   || ((stringAt($original, ($current - 1), 1, "A", "O", "U", "E", "") 
       		                   || ($current == 0))
				      # e.g., 'wachtler', 'wechsler', but not 'tichner'
				   && stringAt($original, ($current + 2), 1, "L", "R", "N", "M", "B", "H", "F", "V", "W", " ", "")) )
				{
					appendPhones( "k" );
				}
				elsif( $current > 0) {
					if( stringAt($original, 0, 2, "MC", "")) {
						# e.g., "McHugh"
						appendPhones( "k" );
					} else {
						appendPhones( "ʧ", "k" );
					}
				} else {
					appendPhones( "ʃ" );
				}
				$current += 2;
				next;
			}
			# e.g, 'czerny'
			if( stringAt($original, $current, 2, "CZ", "")
			    && !stringAt($original, ($current - 2), 4, "WICZ", ""))
			{
				appendPhones( "s", "ʃ" );
				$current += 2;
				next;
			}

			# e.g., 'focaccia'
			if( stringAt($original, ($current + 1), 3, "CIA", "")) {
				appendPhones( "ʃ" );
				$current += 3;
				next;
			}

			# double 'C', but not if e.g. 'McClellan'
			if( stringAt($original, $current, 2, "CC", "")
			    && !(($current == 1) && (charAt($original, 0) eq 'M')))
			    # 'bellocchio' but not 'bacchus'
			{
				if( stringAt($original, ($current + 2), 1, "I", "E", "H", "")
			 	    && !stringAt($original, ($current + 2), 2, "HU", ""))
				{
					# 'accident', 'accede' 'succeed'
					if( (($current == 1)
					    && (charAt($original, $current - 1) eq 'A'))
					    || stringAt($original, ($current - 1), 5, "UCCEE", "UCCES", ""))
					{
						appendPhones( "ks" );
						# 'bacci', 'bertucci', other italian
					}
					else {
						appendPhones( "ʃ" );
					}
					$current += 3;
					next;
				}
				else {	  # Pierce's rule
					appendPhones( "k" );
					$current += 2;
					next;
				}
			}

			if( stringAt($original, $current, 2, "CK", "CG", "CQ", "")) {
				appendPhones( "k" );
				$current += 2;
				next;
			}

			if( stringAt($original, $current, 2, "CI", "CE", "CY", "")) {
				# italian vs. english
				if( stringAt($original, $current, 3, "CIO", "CIE", "CIA", "")) {
					appendPhones( "s", "ʃ" );
				} else {
					appendPhones( "s" );
				}
				$current += 2;
				next;
			}
	
			# else
			appendPhones( "k" );
	
			# name sent in 'mac caffrey', 'mac gregor
			if( stringAt($original, ($current + 1), 2, " C", " Q", " G", "")) {
				$current += 3;
			} elsif( stringAt($original, ($current + 1), 1, "C", "K", "Q", "")
			         && !stringAt($original, ($current + 1), 2, "CE", "CI", "")) {
				$current += 2;
			} else {
				$current += 1;
			}
		}
		elsif( $ch eq 'D' ) {
			if( stringAt($original, $current, 2, "DG", "") ) {
				if( stringAt($original, ($current + 2), 1, "I", "E", "Y", "") ) {
					# e.g. 'edge'
					appendPhones( "ʤ", "j" );
					$current += 3;
				} else {
					# e.g. 'edgar'
					appendPhones( "tk" );
					$current += 2;
				}
			}
			elsif( stringAt($original, $current, 2, "DT", "DD", "")) {
				appendPhones( "t" );
				$current += 2;
			} else {
				appendPhones( "t" );
				$current += 1;
			}
		}
		elsif( $ch eq 'F' ) {
			$current += ( charAt($original, $current + 1) eq 'F' )
				 ? 2
				 : 1
			;
			appendPhones( "f" );
		}
		elsif( $ch eq 'G' ) {
			if( charAt($original, $current + 1) eq 'H' ) {
		      		if( ($current > 0) && !isVowel($original, $current - 1) ) {
					appendPhones( "k" );
					$current += 2;
					next;
				}
				if( $current < 3) {
					# 'ghislane', ghiradelli
					if( $current == 0) {
						if( charAt($original, $current + 2) eq 'I') {
							appendPhones( "j" );
						} else {
							appendPhones( "k" );
						}
						$current += 2;
						next;
				  	}
				}
				# Parker's rule (with some further refinements) - e.g., 'hugh'
				if( (($current > 1)
				    && stringAt($original, ($current - 2), 1, "B", "H", "D", ""))
				    # e.g., 'bough'
				    || (($current > 2)
				    && stringAt($original, ($current - 3), 1, "B", "H", "D", ""))
				    # e.g., 'broughton'
				    || (($current > 3)
				    && stringAt($original, ($current - 4), 1, "B", "H", "")))
				{
					$current += 2;
					next;
				}
			      else
				{
					# e.g., 'laugh', 'McLaughlin', 'cough', 'gough', 'rough', 'tough'
					if( ($current > 2)
					    && (charAt($original, $current - 1) eq 'U')
					    && stringAt($original, ($current - 3), 1, "C", "G", "L", "R", "T", ""))
					{
						appendPhones( "f" );
					}
				    elsif( ($current > 0) && charAt($original, $current - 1) != 'I' )
					{
						appendPhones( "k" );
					}

					$current += 2;
					next;
				}
			}

			if( charAt($original, $current + 1) eq 'N') {
			      	if( ($current == 1) && isVowel($original, 0) && !SlavoGermanic($original)) {
					appendPhones( "kn", "n" );
				}
			      	# not e.g. 'cagney'
				elsif( !stringAt($original, ($current + 2), 2, "EY", "")
				      && (charAt($original, $current + 1) != 'Y')
				      && !SlavoGermanic($original))
				{
					appendPhones( "n", "kn" );
				} else {
					appendPhones( "kn" );
				}
			      $current += 2;
			      next;
			  }

			# 'tagliaro'
			if( stringAt($original, ($current + 1), 2, "LI", "")
			    && !SlavoGermanic($original))
			  {
					appendPhones( "kl", "l" );
			      $current += 2;
			      next;
			  }

			# -ges-,-gep-,-gel-, -gie- at beginning
			if( ($current == 0)
			    && ((charAt($original, $current + 1) eq 'Y')
			    || stringAt($original, ($current + 1), 2, "ES", "EP", "EB", "EL", "EY", "IB", "IL", "IN", "IE", "EI", "ER", "")))
			{
				appendPhones( "k", "j" );
				$current += 2;
				next;
			}

			#  -ger-,  -gy-
			if( (stringAt($original, ($current + 1), 2, "ER", "")
			     || (charAt($original, $current + 1) eq 'Y'))
			    && !stringAt($original, 0, 6, "DANGER", "RANGER", "MANGER", "")
			    && !stringAt($original, ($current - 1), 1, "E", "I", "")
			    && !stringAt($original, ($current - 1), 3, "RGY", "OGY", ""))
			{
				appendPhones( "k", "j" );
				$current += 2;
				next;
			}

			#  italian e.g, 'biaggi'
			if( stringAt($original, ($current + 1), 1, "E", "I", "Y", "")
			    || stringAt($original, ($current - 1), 4, "AGGI", "OGGI", ""))
			{
				# obvious germanic
				if( (stringAt($original, 0, 4, "VAN ", "VON ", "")
				    || stringAt($original, 0, 3, "SCH", ""))
				    || stringAt($original, ($current + 1), 2, "ET", ""))
				{
					appendPhones( "k" );
				}
				elsif( stringAt ($original, ($current + 1), 4, "IER ", "")) {
					# always soft if french ending
					apendPhones( "j" );
				} else {
					endPhones( "j", "k" );
			  	}
			      $current += 2;
			      next;
			}

			$current += (charAt($original, $current + 1) eq 'G')
				 ? 2
				 : 1
			;
			appendPhones( "k" );
		}
		elsif( $ch eq 'H' ) {
			# only keep if first & before vowel or btw. 2 vowels
			if( (($current == 0) || isVowel($original, $current - 1))
			    && isVowel($original, $current + 1))
			{
				appendPhones( "h" );
				$current += 2;
			}
			else {	# also takes care of 'HH'
				$current += 1;
				
			}
		}
		elsif( $ch eq 'J' ) {
			# obvious spanish, 'jose', 'san jacinto'
			if( stringAt($original, $current, 4, "JOSE", "")
			    || stringAt($original, 0, 4, "SAN ", "") )
			{
				if( (($current == 0)
				   && (charAt($original, $current + 4) == ' '))
				   || stringAt($original, 0, 4, "SAN ", "") )
				{
					appendPhones( "h" );
				}
				else {
					appendPhones( "j", "h" );
				}
				$current += 1;
				next;
			}

			if(  ($current == 0) && !stringAt($original, $current, 4, "JOSE", "") ) {
				# Yankelovich/Jankelowicz
				appendPhones( "ʤ", "a" );
			} elsif( # spanish pron. of e.g. 'bajador'
				 IsVowel($original, $current - 1)
				 && !SlavoGermanic($original)
				 && ((charAt($original, $current + 1) eq 'A')
				 || (charAt($original, $current + 1) == 'O')) )
			{
				appendPhones( "j", "h" );
			}
			elsif( $current == $last) {
				appendPhones( "ʤ", "" );
			}
			elsif( !stringAt($original, ($current + 1), 1, "L", "T", "K", "S", "N", "M", "B", "Z", "")
			       && !stringAt($original, ($current - 1), 1, "S", "K", "L", "")) 
                      	{
				appendPhones( "j" );
			}

			$current += (charAt($original, $current + 1) eq 'J') # it could happen! 
				 ? 2
				 : 1
			;
		}
		elsif( $ch eq 'K' ) {
			if( charAt($original, $current + 1) != 'H') {
				$current += (charAt($original, $current + 1) eq 'K')
					 ? 2
					 : 1
				;
				$primary .= "k";
			}
			else {
				# husky "kh" from arabic
				$secondary .= "x";
				$current += 2;
			}
			$secondary .= "k";
		}
		elsif( $ch eq 'L' ) {
			if( charAt($original, $current + 1) eq 'L') {
				# spanish e.g. 'cabrillo', 'gallegos'
				if( (($current == ($length - 3))
				   && stringAt($original, ($current - 1), 4, "ILLO", "ILLA", "ALLE", ""))
				   || ((stringAt($original, ($last - 1), 2, "AS", "OS", "")
				   || stringAt($original, $last, 1, "A", "O", ""))
				   && stringAt($original, ($current - 1), 4, "ALLE", "")))
				{
					appendPhones( "l", "" );
			   		$current += 2;
					next;
				}
				$current += 2;
			}
			else {
				$current += 1;
			}
			appendPhones( "l" );
		}
		elsif( $ch eq 'M' ) {
			if( (stringAt($original, ($current - 1), 3, "UMB", "") 
			   && ((($current + 1) == $last)
			   || stringAt($original, ($current + 2), 2, "ER", "")))
			   # 'dumb','thumb'
			   || (charAt($original, $current + 1) eq 'M'))
			{
				$current += 2;
			} else {
				$current += 1;
			}
			appendPhones( "m" );
		}
		elsif( $ch eq 'N' ) {
			if( charAt($original, $current + 1) eq 'Y') {
				$primary .= "ɲ";
				$current += 2;
			} else {
				$current += (charAt($original, $current + 1) eq 'N')
					 ? 2
					 : 1
				;
				$primary .= "n";
		  	}
			$secondary .= "n";
		}
		elsif( $ch eq 'Ñ' ) {
			appendPhones( "ɲ" );
			$current += 1;
		}
		elsif( $ch eq 'P' ) {
			if( charAt($original, $current + 1) eq 'H') {
				appendPhones( "f" );
				$current += 2;
		  	}
			# also account for "campbell", "raspberry"
			elsif( stringAt($original, ($current + 1), 1, "P", "B", "")) {
				$current += 2;
			} else {
				$current += 1;
			}

			appendPhones( "p" );
		}
		elsif( $ch eq 'Q' ) {
			if( charAt($original, $current + 1) eq 'U') {
				$primary .= "kw";
				$current += 1;  # total of 2
			}
			else {
				$current += (charAt($original, $current + 1) eq 'Q')
					 ? 2
					 : 1
				;
				$primary .= "k'";
			}

			$secondary .= "k";
		}
		elsif( $ch eq 'R' ) {
			# french e.g. 'rogier', but exclude 'hochmeier'
			if( ($current == $last)
			    && !SlavoGermanic($original)
			    && stringAt($original, ($current - 2), 2, "IE", "")
			    && !stringAt($original, ($current - 4), 2, "ME", "MA", ""))
			{
				appendPhones( "", "r" );
			}
			else
			{
				appendPhones( "r" );
			}

			$current += (charAt($original, $current + 1) eq 'R')
				 ? 2
				 : 1
			;
		}
		elsif( $ch eq 'S' ) {
			# special cases 'island', 'isle', 'carlisle', 'carlysle'
			if( stringAt($original, ($current - 1), 3, "ISL", "YSL", ""))
			{
			      $current += 1;
			      next;
			}

			# special case 'sugar-'
			if( ($current == 0) && stringAt($original, $current, 5, "SUGAR", "") ) {
				appendPhones( "ʃ", "s" );
			      $current += 1;
			      next;
			}

			if( stringAt($original, $current, 2, "SH", "") ) {
				# germanic
				if( stringAt ($original, ($current + 1), 4, "HEIM", "HOEK", "HOLM", "HOLZ", "")) {
					appendPhones( "s" );
				} else {
					appendPhones( "ʃ" );
				}
		      		$current += 2;
				next;
			}

			# italian & armenian
			if( stringAt($original, $current, 3, "SIO", "SIA", "") || stringAt($original, $current, 4, "SIAN", "")) {
				if( !SlavoGermanic($original)) {
					appendPhones( "s", "ʃ" );
				} else {
					appendPhones( "s" );
				}
			      $current += 3;
			      next;
			  }

			# german & anglicisations, e.g. 'smith' match 'schmidt', 'snider' match 'schneider' 
			#   also, -sz- in slavic language altho in hungarian it is pronounced 's'
			if( (($current == 0)
			     && stringAt($original, ($current + 1), 1, "M", "N", "L", "W", ""))
			    || stringAt($original, ($current + 1), 1, "Z", ""))
			  {
				appendPhones( "s", "ʃ" );
				$current += (stringAt($original, ($current + 1), 1, "Z", ""))
					 ? 2
					 : 1
				;
			      next;
			  }

			if( stringAt($original, $current, 2, "SC", "")) {
				# Schlesinger's rule
				if( charAt($original, $current + 2) eq 'H') {
				  	# dutch origin, e.g. 'school', 'schooner'
					if( stringAt($original, ($current + 3), 2, "OO", "ER", "EN", "UY", "ED", "EM", "")) {
						# 'schermerhorn', 'schenker'
						if( stringAt($original, ($current + 3), 2, "ER", "EN", "")) {
							appendPhones( "ʃ", "sk" );
						} else {
							appendPhones( "sk" );
						}
						$current += 3;
						next;
					}
					elsif( ($current == 0) && !IsVowel($original, 3) && (charAt($original, 3) != 'W')) {
						appendPhones( "ʃ", "s" );
					} else {
						appendPhones( "ʃ" );
					}
					$current += 3;
					next;
				}

				if( stringAt($original, ($current + 2), 1, "I", "E", "Y", "")) {
					appendPhones( "S", "s" );
					$current += 3;
					next;
				}

				# else

				appendPhones( "sk" );
				$current += 3;
				next;
			}

			# french e.g. 'resnais', 'artois'
			if( ($current == $last) && stringAt($original, ($current - 2), 2, "AI", "OI", "") ) {
				appendPhones( "", "s" );
			} else {
				appendPhones( "s" );
			}

			$current += (stringAt($original, ($current + 1), 1, "S", "Z", ""))
				 ? 2
				 : 1
			;
		}
		elsif( $ch eq 'T' ) {
			if( stringAt($original, $current, 4, "TION", "")) {
				appendPhones( "ʃ" );
				$current += 3;
		  	}
			elsif( stringAt($original, $current, 3, "TIA", "TCH", "")) {
				appendPhones( "ʃ" );
				$current += 3;
		  	}

			if( stringAt($original, $current, 2, "TH", "" )
			    || stringAt($original, $current, 3, "TTH", ""))
		  	{
				# special case 'thomas', 'thames' or germanic
				if( stringAt($original, ($current + 2), 2, "OM", "AM", "")
				  || stringAt($original, 0, 4, "VAN ", "VON ", "")
				  || stringAt($original, 0, 3, "SCH", ""))
				{
					appendPhones( "t" );
				}
				else
				{
					appendPhones( "Θ", "t" );
				}
				$current += 2;
		  	}
			elsif( stringAt($original, ($current + 1), 1, "T", "D", "")) {
				$current += 2;
			} else {
				$current += 1;
				appendPhones( "t" );
			}
		}
		elsif( $ch eq 'V' ) {
			$current += (charAt($original, $current + 1) eq 'V')
				 ? 2
				 : 1
			;
			appendPhones( "f" );
		}
		elsif( $ch eq 'W' ) {
			# can also be in middle of word
			if( stringAt($original, $current, 2, "WR", "") ) {
				appendPhones( "r" );
				$current += 2;
			}
			elsif( ($current == 0)
			    && (IsVowel($original, $current + 1)
			    || stringAt($original, $current, 2, "WH", "")))
			{
		 		# Wasserman should match Vasserman
				if( IsVowel($original, $current + 1)) {
					appendPhones( "a", "f" );
				} else {
					# need Uomo to match Womo
					appendPhones( "a" );
				}
			}

			# Arnow should match Arnoff
			elsif( (($current == $last) && IsVowel($original, $current - 1))
			    || stringAt($original, ($current - 1), 5, "EWSKI", "EWSKY", "OWSKI", "OWSKY", "")
			    || stringAt($original, 0, 3, "SCH", ""))
			{
				appendPhones( "", "f" );
				$current += 1;
			}

			# polish e.g. 'filipowicz'
			elsif( stringAt($original, $current, 4, "WICZ", "WITZ", "") ) {
				appendPhones( "ts", "fx" );
				$current += 4;
				next;
			}

			# else skip it
			$current += 1;
		}
		elsif( $ch eq 'X' ) {
			# french e.g. breaux
			if( !(($current == $last)
			   && (stringAt($original, ($current - 3), 3, "IAU", "EAU", "")
			   || stringAt($original, ($current - 2), 2, "AU", "OU", ""))))
			{
				appendPhones( "ks" );
			}
                  
			$current += ( stringAt($original, ($current + 1), 1, "C", "X", "") )
				 ? 2
				 : 1
			;
		}
		elsif( $ch eq 'Z' ) {
			# chinese pinyin e.g. 'zhao'
			if( charAt($original, $current + 1) eq 'H') {
				appendPhones( "j" );
				$current += 2;
				next;
			} elsif( stringAt($original, ($current + 1), 2, "ZO", "ZI", "ZA", "")
			    || (SlavoGermanic($original)
			    && (($current > 0)
			    && charAt($original, $current - 1) != 'T')))
			{
				appendPhones( "s", "ts" );
			}
			else {
				appendPhones( "s" );
			}

			$current += (charAt($original, $current + 1) eq 'Z')
				 ? 2
				 : 1
			;
			next;
		}
		else {
			$current += 1;
		}
	    }

	( $primary, $secondary );

}

sub reverse_key
{
	print STDERR, "not implemented.\n";
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__


=encoding utf8


=head1 NAME

Text::TransMetaphone::en_US - Transcribe American English words into IPA symbols.

=head1 SYNOPSIS

This module is used by L<Text::TransMetaphone> and need not be used
directly.

=head1 DESCRIPTION

This module is a simple port of Maurice Aubrey's Text::DoubleMetaphone
module to work under the TransMetaphone premise.

=head1 AUTHOR

Copyright 2000, Maurice Aubrey E<lt>maurice@hevanet.comE<gt>.
All rights reserved.  Modified for IPA symbols by Daniel Yacob.

This code is based heavily on the C++ implementation by
Lawrence Philips, and incorporates several bug fixes courtesy
of Kevin Atkinson E<lt>kevina@users.sourceforge.netE<gt>.

This module is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.  

=head1 STATUS

The module is only partially ported to TransMetaphone.  Only two keys are
returned at this time I<NOT> including a terminal regex key. A "reverse_key"
function has not yet been implemented.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2003-2025, Daniel Yacob C<< <dyacob@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 SEE ALSO

=head2 Man Pages

L<Text::Metaphone>, L<Text::Soundex>

=head2 Additional References

Philips, Lawrence. I<C/C++ Users Journal>, June, 2000.
L<http://www.cuj.com/articles/2000/0006/0006d/0006d.htm?topic=articles>

Philips, Lawrence. I<Computer Language>, Vol. 7, No. 12 (December), 1990.

Kevin Atkinson (author of the Aspell spell checker) maintains
a page dedicated to the Metaphone and Trans Metaphone algorithms at 
L<http://aspell.sourceforge.net/metaphone/>

=cut
