#!/usr/bin/perl -w
#
# This script loads in a large file of words into a hash (using
# Perl's hashes) and sees how much memory is taken up

use strict;
use GTop;

my %words;
my $i;

open(WORDS, "/usr/share/dict/words");
while (<WORDS>) {
  $words{$_} = $i++;
}
close(WORDS);

my $gtop = GTop->new();
print "Memory with Perl hash: " . $gtop->proc_mem($$)->size . "\n";
