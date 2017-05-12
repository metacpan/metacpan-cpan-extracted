#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Lingua::JA::Moji ':all';
use Text::Fuzzy;
use utf8;
binmode STDOUT, ":utf8";
my $infile = '/home/ben/data/edrdg/edict';
open my $in, "<:encoding(EUC-JP)", $infile or die $!;
my @kana;
while (<$in>) {
    my $kana;
    if (/\[(\p{InKana}+)\]/) {
	$kana = $1;
    }
    elsif (/^(\p{InKana}+)/) {
	$kana = $1;
    }
    if ($kana) {
	$kana = kana2katakana ($kana);
	push @kana, $kana;
    }
}
printf "Starting fuzzy searches over %d lines.\n", scalar @kana;
search ('ウオソウコ');
search ('アイウエオカキクケコバビブベボハヒフヘホ');
search ('アルベルトアインシュタイン');
search ('バババブ');
search ('バババブアルベルト');
exit;

sub search
{
    my ($silly) = @_;
    my $max = 10;
    my $search = Text::Fuzzy->new ($silly, max => $max);
    my $n = $search->nearest (\@kana);
    if (defined $n) {
	printf "$silly nearest is $kana[$n] (distance %d)\n",
	    $search->last_distance ();
    }
    else {
	printf "Nothing like '$silly' was found within $max edits.\n";
    }
}

