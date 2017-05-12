#!/usr/bin/perl

use strict;
use warnings;
use v5.14;

#
# Print out at frequency order of texts based patterns
#

my %patstats;

while(my $line=<STDIN>) {
    chomp $line;
    $line =~ s/\t/ /g;
    $line =~ s/^\s+//g;
    $line =~ s/\s+$//g;
    $line =~ s/\s+/ /g;
#    say $line;
    my $pattern;
    my @items = split /\s/,$line;
    while (scalar(@items)) {
	$pattern //= shift @items;
	$patstats{$pattern}++;
#	say "#".$pattern;

	while (scalar(@items)) {
	    $pattern .= " ".shift @items;
#	    say "#".$pattern;
	    $patstats{$pattern}++;
	}
    }
}

my @sorted_patterns = sort { 
    my $order = $patstats{$b} <=> $patstats{$a};

    unless ($order) {
	# compare pattern-strings if same frequency ($order == 0)
	$order = $a cmp $b;
    }
    
    $order;
} keys %patstats;

for my $pattern (@sorted_patterns) {
    say $pattern;
}
