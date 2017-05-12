#! /usr/bin/env perl
my ($loaded, $used);
BEGIN { $| = 1; print "1..2\n" }
END { print "not ok 1\n" unless $loaded;
      print "not ok 2\n" unless $used }
use Text::Bastardize;
use strict;
use warnings;
$loaded = 1;

print "ok 1\n";

my $t = "O most adorablest of beautyfuls, fluffy bunny my viscerea be thine!";
my $text = Text::Bastardize->new->charge($t);
print "text.........@{[$text->peek]}\n";
print "rot13........@{[$text->rot13]}\n";
print "k3wlt0k......@{[$text->k3wlt0k]}\n";
print "rdct.........@{[$text->rdct]}\n";
print "pig..........@{[$text->pig]}\n";
print "rev..........@{[$text->rev]}\n";
print "censor.......@{[$text->censor]}\n";
print "n20e.........@{[$text->n20e]}\n";
print "disemvowel...@{[$text->disemvowel]}\n";
print "text.........$t\n";

$used = 1;
print "ok 2\n"
