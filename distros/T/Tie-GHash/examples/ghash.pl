#!/usr/bin/perl -w
#
# This script loads in a large file of words into a hash (using
# Tie::GHash) and sees how much memory is taken up

use strict;
use GTop;
use Tie::GHash;

tie my %words, 'Tie::GHash';
my $i;

open(WORDS, "/usr/share/dict/words");
while (<WORDS>) {
  $words{$_} = $i++;
}
close(WORDS);

my $gtop = GTop->new();
print "Memory with Tie::GHash: " . $gtop->proc_mem($$)->size . "\n";
