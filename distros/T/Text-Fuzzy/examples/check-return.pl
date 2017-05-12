#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Text::Fuzzy;
my $tf = Text::Fuzzy->new ('calamari', max => 1);
my @words = qw/Have you ever kissed in the moonlight
	       In the grand and glorious
	       Gay notorious
	       South American Way?/;
my $index = $tf->nearest (\@words);
if (defined $index) {
    printf "Found at $index, distance was %d.\n",
    $tf->last_distance ();
}
else {
    print "Not found anywhere.\n";
}


