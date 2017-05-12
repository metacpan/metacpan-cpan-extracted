#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Text::Fuzzy 'distance_edits';
my @words = (qw/who where what when why/);
my $tf = Text::Fuzzy->new ('whammo');
my @nearest = $tf->nearestv (\@words);
print "@nearest\n";
# Prints "who what"
print $tf->last_distance (), "\n";
# Prints 3, the number of edits needed to turn "whammo" into "who"
# (delete a, m, m) or into "what" (replace m with t, delete m, delete
# o).
my ($distance, $edits) = distance_edits ('whammo', 'who');
print "$edits\n";
# Prints kkdddk, keep w, keep h, delete a, delete m, delete m, keep o.

