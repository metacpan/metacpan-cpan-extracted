#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use blib;
use jsFind;

my $dict = '/usr/share/dict/words';

if (! -r $dict) {
	plan skip_all => "no $dict";
} else {
	plan tests => 1;
}

BEGIN { use_ok('jsFind'); }

my $t = new jsFind B => 20;

my $max = 10000;

if (-r $dict) {
	diag "making B-Tree from $max words in $dict";

	open(D, "$dict") || die "can't open '$dict': $!";

	my $i = 0;

	while (<D>) {
		chomp;

		$t->B_search(Key => $_,
			Data => {
				"$dict" => {
						t => "word: $_",
						f => 1,
					}
				},
			Insert => 1,
			Append => 1,
		);
		$i++;
		last if ($i > $max);
	}

	close(D);

	if (open(T,"> words.txt")) {
		print T $t->to_string;
		close(T);
	}
	diag "words.txt created";

	if (open(T,"> words.dot")) {
		print T $t->to_dot;
		close(T);
	}
	diag "words.dot created";

	cmp_ok($t->to_jsfind(dir=>"./html/words"), '==', $max, " jsfind index");
}


