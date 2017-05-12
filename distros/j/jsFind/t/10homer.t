#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;
use blib;
use jsFind;
use Data::Dumper;

BEGIN { use_ok('jsFind'); }

my $t = new jsFind B => 200;

my $file = shift @ARGV || 't/homer.txt';

ok(-e $file, "reading input file $file");

my $line = 0;
my $text = '';
my %words_usage;
my $word_count = 0;
my $max_words;
#$max_words = 100;

my $res;

my $full_text;

ok(open(U, $file), "open $file");
while(<U>) {
	chomp;
	$line++;
	next if (/^\s*$/);

	$full_text = "$line: ";

	my %usage;

	my @words = split(/\s+/,lc($_));

	foreach (@words) {
		$usage{$_}++;
	}

	foreach my $word (@words) {

		next if ($word eq '');

		$words_usage{"$word $line"} = $usage{$word};

		$res->{$word}->{$line} = $usage{$word};

		$t->B_search(
			Key => $word,
			Data => { "$line" => {
				t => "Odyssey line $line",
				f => $usage{$word},
				},
			},
			Insert => 1,
			Append => 1,
		);

		$word_count++;

		$full_text .= "$word ";

	}

	$full_text = "\n";

	last if ($max_words && $word_count >= $max_words);
}

my $test_data = Dumper($res);
$test_data =~ s/=>/:/gs;
$test_data =~ s/\$VAR1/var test_data/;
ok(open(JS, "> html/test_data.js"), "test_data.js");
print JS $test_data;
close(JS);

ok($test_data, "test_data saved");

my $sum = 0;
ok(open(TD, "> homer_freq.txt"), "homer_freq.txt");
foreach my $w (keys %words_usage) {
	print TD "$w: $words_usage{$w}\n";
	$sum += $words_usage{$w};
}
close(TD);
diag "homer_freq.txt created";

if (open(T,"> homer_text.txt")) {
	print T $full_text;
	close(T);
}
diag "homer_text.txt created";

if (open(T,"> homer_words.txt")) {
	print T $t->to_string;
	close(T);
}
diag "homer_words.txt created";

my $total_words = scalar keys %words_usage;

cmp_ok($t->to_jsfind(dir=>"./html/homer"), '==', $total_words, " jsfind index with $total_words words");

#print Dumper($t);
