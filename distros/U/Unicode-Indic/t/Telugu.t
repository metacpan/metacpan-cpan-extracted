use Unicode::Indic::Telugu;
use strict;

print "1..4\n";

my $i = 1;

# Can make an object?
my $lang = Unicode::Indic::Telugu->new ()  or print "noti ";
printf "ok %d\n", $i++;

# Object is of proper type?
print "not " if (ref($lang) ne "Unicode::Indic::Telugu");
printf "ok %d\n", $i++;

# Can translate a string?
my $text = "Sriiraama jayaraama jaya jaya raama";
my $out = $lang-> translate($text) or print "not ";
printf "ok %d\n", $i++;

# Got nonempty output?
print "not " if ($out eq '');
printf "ok %d\n", $i++;




