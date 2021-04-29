#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use Unicode::Confuse ':all';

binmode STDOUT, ":encoding(utf8)";

sub obfuscate
{
    for (@_) {
	my @letters = split '', $_;
	my $out = '';
	my $ok;
	for my $letter (@letters) {
	    my @similar = similar ($letter);
	    if (@similar) {
		$ok = 1;
		my $n = scalar (@similar);
		my $r = int (rand ($n));
		$out .= $similar[$r];
	    }
	    else {
		$out .= $letter;
	    }
	}
	if (! $ok) {
	    print "No confusables in '$_'.\n";
	}
	else {
	    print "$_ -> $out\n";
	}
    }
}

obfuscate ('paypal', '月火水木金土日');
