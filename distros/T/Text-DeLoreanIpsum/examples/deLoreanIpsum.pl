use strict;
use warnings;
use Text::DeLoreanIpsum;
use vars qw/$opt_v $opt_c $opt_l $opt_w $opt_s $opt_p/;
use Getopt::Std;

getopts("vlc:w:s:p:");

if ($opt_v) {
    print usage();
    exit 0;
}

die usage()
    if ((defined($opt_w) + defined($opt_s) + defined($opt_p)) > 1);

my $delorean = Text::DeLoreanIpsum->new;

if ($opt_l) {
    print $delorean->characters();
} elsif ($opt_w) {
    print $delorean->words($opt_w, $opt_c);
} elsif ($opt_s) {
    print $delorean->sentences($opt_s, $opt_c);
} elsif ($opt_p) {
    print $delorean->paragraphs($opt_p, $opt_c);
} else {
    print $delorean->paragraphs(1);
}

sub usage {
    return <<USAGE;
$0 - Generate random Latin looking text using Text::DeLoreanIpsum

Usage:
    $0 -l
    $0 [-c CHARACTER] -w NUMBER_OF_WORDS
    $0 [-c CHARACTER] -s NUMBER_OF_SENTENSES
    $0 [-c CHARACTER] -p NUMBER_OF_PARAGRAPHS

-l, -w, -s, and -p are mutually exclusive.
USAGE
}
