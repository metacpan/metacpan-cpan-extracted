#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Text::Fuzzy;
my @words = (qw/who where what when why/);
my $tf = Text::Fuzzy->new ('whammo');
my @nearest = $tf->nearestv (\@words);
print "@nearest\n";
print $tf->last_distance (), "\n";
# Prints 3, the number of edits needed to turn "whammo" into "who"
# (delete a, m, m) or into "what" (replace m with t, delete m, delete
# o).
