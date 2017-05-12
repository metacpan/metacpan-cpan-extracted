#!/usr/local/bin/perl -w
###############################################################################
# Script from http://use.perl.org/~jdavidb/journal/8055
# modified by russell
# modified by barbie (March 2007)
###############################################################################

use strict;
use WWW::UsePerl::Journal;

print "Supply usernames to look up on the command line\n"
    if (~~@ARGV == 0);

for my $user (@ARGV) {
    my $journal = WWW::UsePerl::Journal->new($user);
    my %entries = $journal->entryhash;
    my %count;

    for my $entrynum (sort keys %entries) {
        my $entry = $entries{$entrynum};
        my $date = $entry->date;
        my($month, $year) = ($date->mon, $date->year);
        $month = sprintf "%02d", $month;
        $count{"$year$month"}++;
    }

    print "$_:\t$count{$_}\n"   for(sort keys %count)
}
