#!/usr/bin/perl -w

use strict;
use utf8;
require Text::Metaphone::Amharic;


sub printList
{
my (@list) = @_;

	for my $j (0..$#list) {
		if ( $#list == 0 ) {
			print "$list[$j]";
		}
		elsif ( $j == $#list ) {
			print "and $list[$j]";
		}
		elsif ( $j == $#list-1 ) {
			print "$list[$j] ";
		}
		else {
			print "$list[$j], ";
		}
	}

}

main:
{
my (@cPhones, $can, @list, @ePhones, $count, $match, $innerMatch, $type, $outer);

my $granularity = ( @ARGV ) ? $ARGV[0] : "low" ;

my $am = new Text::Metaphone::Amharic ( granularity => $granularity );

my (@Matches, @Misses);
my ($counter, $errors, $matches) = (0,0,0);

while ( <DATA> ) {
	if ( /^#/ ) {
		s/^#\s+//;
		$type = $_;
		next;
	}
	chomp;
	next unless /\w/;
	$counter++;
	s/ //g;
	($can, @list) = split ( /[\t,]/ );
	(@cPhones) = $am->metaphone ( $can );
	$outer = $match = 0;
	@Matches = ();
	@Misses  = ();

	print $type;
	print "$can [", "$#cPhones]፦\n";

	foreach my $error (@list) {
		$errors++;
		print "  ", $outer+1,") $can vs $error፦\n";
		@ePhones  = $am->metaphone ( $error );
		for my $j (0..$#cPhones-1) {
			my $canPhone = $cPhones[$j];
			print "    ----------------\n" if ( $j );
			print "    c-", $j+1, ") $canPhone፦\n";
			$innerMatch = $count = 0;
			for my $i (0..$#ePhones-1) {
				my $ePhones = $ePhones[$i];
				$count++;
				printf "      e-%i) $ePhones", $count;
				if ( $canPhone eq $ePhones ) {
					print " - match!\n";
					$innerMatch = $match = 1;
					$matches++;
					push (@Matches,$error);
					goto LIST;
				}
				print "\n";
			}
		}
		LIST:
		unless ( $innerMatch ) {
			print "      no matches found!\n";
			push (@Misses,$error);
		}
		print "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";
		$outer++;

	}

	if ( @Matches ) {
		print "$can ";
		print "matched ";
		printList ( @Matches );
		if ( @Misses ) {
			print " and did NOT match ";
			printList ( @Misses );
		}
	}
	else {
		print "NO METAPHONE MATCH FOR $can and ";
		printList ( @list );
	}
	print "!\n";
	print "====================================\n";

}

print "$counter words matched $matches of $errors error words.\n";

}


=head1 NAME

matchtest.pl - Amharic Metaphone demonstrator for 116 sample words.

=head1 SYNOPSIS

./matchtest.pl [ low | medium | high ]

=head1 DESCRIPTION

This is a simple demonstration script that compares the Amharic Metaphone keys
generated for 116 sample words compared against 166 errors.  Comparisons of
canonical vs error keys stop upon the first match.  The "granulariy" can be
set at the command line to examine the impact on matching ("low" level is the
default).  Matches are not expected in all cases.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 SEE ALSO

L<Text::Metaphone::Amharic>

=cut


__DATA__
# Type 1: Syllographic Redundancy
ሆሣዕና	ሆሳእና, ሆሳና, ሆሣና
ሐምሌ	ሀምሌ, ሃምሌ, ኃምሌ
ሒሳብ	ሂሣብ
ሕግ	ህግ
ሥላሴ	ስላሴ, ስላሤ, ሥላሤ
ሥጋ	ስጋ
ታኅሣሥ	ታህሳስ
ኀምሳ	ኃምሳ, ሃምሳ
ኀይለ	ኃይለ, ሀይለ, ሃይለ, ሐይለ 
ድኅና	ደህና
ዐወቀ	አወቀ
ዓለምፀሐይ	ዓለምፀሃይ, ዓለምፀሀይ,ዓለምጸሐይ, ዓለምጸሃይ, ዓለምጸሀይ, ዐለምፀሐይ, ዐለምፀሃይ, ዐለምፀሀይ, ዐለምጸሐይ, ዐለምጸሃይ, ዐለምጸሀይ, አለምፀሐይ, አለምፀሃይ, አለምፀሀይ, አለምጸሐይ, አለምጸሃይ, አለምጸሀይ
ዓሣ	አሳ, ዓሣ
ዕንቍጣጣሽ	እንቁጣጣሽ
ወሀ	ውኃ, ዉሃ


# Type 2: Glypheme Misidentification
ሴንሰርሺፕ	ሴንሰርሺኘ
ቈነሰ	ቆነሰ
ቈይ	ቆይ
ቈጠረ	ቀጠረ, ቆጠረ
ቍጥራቸውም	ቁጥራቸውም
ቍረጥ	ቁረጥ
ቍርባን	ቁርባን
ቍር	ቁር
ቍርስ	ቁርስ
ብርኰት	ብርኮት
ነኍላላ	ነሁላላ
ነው	ነዉ
አውሮፕላን	አውሮኘላን
ኢትዮጵያ	ኢትዮዽያ
ኮከብ	ኰከብ
ኮኦፕሬሽን	ኮኦኘሬሽን
ኰነነ	ኮነነ
ኵላብ	ኩላብ
ደቈስ	ደቆስ
ዲፕሎማት	ዲኘሎማት
ዲፕሎማሲ	ዲኘሎማሲ
ዲሲፕሊን	ዲሲኘሊን
ጎንዳር	ጐንዳር
ጎጃም	ጐጃም
ጕበት	ጉበት
ጕዳይ	ጉዳይ
ፕሪሚየር	ኘሪሚየር
ፕራይቬታይዜሽን	ኘራይቬታይዜሽን
ፕሬስ	ኘሬስ
ፕሬዚዳንት	ኘሬዚዳንት
ፕሮጀክት	ኘሮጀክት
ፕሮግራም	ኘሮግራም
ፕሮፌሰር	ኘሮፌሰር
ፕሮፖጋንዳ	ኘሮፖጋንዳ, ፕሮፓጋንዳ, ኘሮፓጋንዳ
ፖሊቲካ	ፓሊቲካ


# Type 3: False Ge'ezisms
ሀገር	ኃገር
ሁለት	ኁለት, ኹለት
ሁሉ	ኍሉ, ኹሉ
ምልክት	ምልእክት, ምልዕክት
ቀለሞች	ቀለማት
ትዕግሥት	ትግስት, ትዕግዕስት, ትግዕሥት
አየ	ዐየ


# Type 4: Assimilations and Alternations
ሀገር	አገር
ላንፋ	ላምፋ
ሸንብራ	ሸምብራ
ብሎአቸው	ብሎዋቸው
ቅርንፉድ	ቅርምፉድ
ተባዕት	ተባት
ኀምሳ	አምሳ
አንበሣ	አምበሳ
አንበጣ	አምበጣ
እንቢ	እምቢ
እንብርት	እምብርት
አንፋር	አምፋር
ከበጉዋይ	ከበጓይ, ከበጕይ
ውሽንፍር	ውሽምፍር
ወንበር	ወምበር
ዝንብ	ዝምብ
ግልንቢጥ	ግልምቢጥ
ግንብ	ግምብ
ግንፎ	ግምፎ
ጥንብ	ጥምብ


# Type 5: Orthographic Abbreviations and Elisions
መልአክ	መላክ
ሚያዝያ	ሚያዚያ
ማርያም	ማሪያም
ምክንያት	ምክኒያት
በንደ	በእንደ
ሰማንያ	ሰማኒያ
ነጉሣውያን	ነጉሣዊያን
አንባብያን	አንባቢያን
አብዮታውያን	አብዮታዊያን
ኢትዮጵያውያን	ኢትዮጵያዊያን
አንባብያን	አንባቢያን
ክርስቲያን	ክርስትያን
ወንጌላውያን	ወንጌላዊያን
የአምርኛ	ያማርኛ


# Type 6: Disjoint Labiovelars
ሆኗል	ሆኖዋል, ሆኖአል
ቍንጫ	ቁንጫ
ተቃውሞዋቸ	ተቃውሞአቸ
በእርስዋም	በእርሷም
ዓድዋ	ዓዷ, አድዋ
ይዟል	ይዞአል
ጆሮአቸውን	ጆሮዋቸውን
ገልጿል	ገልፀዋል
ጐረመሰ	ጎረመሳ
ጡዋት	ጥዋት, ጠዋት, ጧት


# Type 7: Dialect Variations
ሂጅ	ሂጂ
አይዶለም	አይደለም
ዐመፀ	ዐመጠ
ዓፄ	ዓጤ, አፄ, ሐፄ


# Type 8: Foreign Language Transcription
ቴክኖሎጂ	ቴክኒዎሎጂ
አቪኖር	አቢኖር
ኢሜይል	ኢሜል, ኤሜል, ኤሜይል
ኢንተርኔት	ኢንተርነት, ኢንቴርኔት, ኢንቴርኔት
ኮምፒዩተር	ኮምፒውተር
ፕሬዚዳንት	ፕረዚደንት


# Type 9: Mistrikes
መልአክ	መላክ
ሥርዓት	ሥርአት, ሥራት
ኢትዮጵያ	ኢትዮፕያ
ጤና	ጠና, ቴና, ጤኛ
ወጤት	ወጤጥ
