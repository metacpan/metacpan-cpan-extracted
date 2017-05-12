#!/usr/local/bin/perl -w
###############################################################################
# Script from http://use.perl.org/~jdavidb/journal/8055 
# modified by russell
###############################################################################

use strict;
use WWW::UsePerl::Journal;

print "Supply usernames to look up on the command line\n"
    if (~~@ARGV == 0);

for my $user (@ARGV) {
    my $journal = WWW::UsePerl::Journal->new($user);
    my @entries = $journal->entryids();

    # Originally I took the date of the first and last entries, but
    # actually I want the current date as an endpoint.  (If you stop
    # posting, that means your average rate should gradually decrease
    # as time progresses.)
    my $firstdate = $journal->entry($entries[0])->date;
    my $numentries = scalar @entries;

    use Time::Piece;
    my $lastdate = localtime;
    my $interval = $lastdate - $firstdate;

    my $per_day = $numentries / $interval->days;

    print "$user has written $per_day entries per day\n";
}
