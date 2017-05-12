#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Lingua::JA::Moji ':all';
use Text::Fuzzy;
use Time::HiRes 'time';
use utf8;
binmode STDOUT, ":utf8";
my $infile = '/home/ben/data/edrdg/edict';
open my $in, "<:encoding(EUC-JP)", $infile or die $!;
my @kanji;
while (<$in>) {
    my $kanji;
    if (/^(\p{InCJKUnifiedIdeographs}+)/) {
	$kanji = $1;
    }
    if ($kanji) {
	push @kanji, $kanji;
    }
}
printf "Starting fuzzy searches over %d lines.\n", scalar @kanji;
search ('幾何学校');
search ('阿部総理大臣');
search ('何校');
exit;

sub search
{
    my ($silly) = @_;
    my $start = time ();
    my $search = Text::Fuzzy->new ($silly);
    my $n = $search->nearest (\@kanji);
    my $max = 3;
    $search->set_max_distance ($max);
    if (defined $n) {
	printf "The nearest to \"$silly\" is $kanji[$n] (distance %d)\n",
	    $search->last_distance ();
    }
    else {
	print "Nothing like '$silly' was found within $max edits.\n";
    }
    my $end = time ();
    printf "Fuzzy search took %g seconds.\n", ($end - $start);
}

