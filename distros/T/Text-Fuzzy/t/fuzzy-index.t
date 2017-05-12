use warnings;
use strict;
use Test::More;
use Text::Fuzzy 'fuzzy_index';

my ($distance, $edits) = fuzzy_index ('dog', 'dawg', 1);

is ($distance, 2);
ok ($edits eq 'krik' || $edits eq 'kirk' # Oh but it's true As we went
                                         # warp factor two And I met
                                         # all of the crew Where's
                                         # Captain Kirk?
);

#print "$edits\n";


my $haystack = 'I beamed aboard the Starship Enterprise What I felt what I saw was a total surprise';
my $needle = 'whas';
#$Text::Fuzzy::verbose = 1;
my ($position, $editz, $mindist) = fuzzy_index ($needle, $haystack);
cmp_ok ($position, '==', 55);
like ($editz, qr/^kkk[dr]$/);
cmp_ok ($mindist, '==', 1);
note "$editz";
note substr ($haystack, $position - length ($needle), length ($needle));
done_testing ();
exit;

# Where's Spock?
