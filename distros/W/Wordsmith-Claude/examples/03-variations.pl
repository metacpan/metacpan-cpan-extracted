#!/usr/bin/env perl
#
# Get multiple variations
#
use strict;
use warnings;
use lib 'lib', '../lib';

use Wordsmith::Claude qw(rewrite);
use IO::Async::Loop;

my $loop = IO::Async::Loop->new;

my $text = "This led to some other ideas but essentially, claude has prompted claude, into claude into refactoring in a async loop of claudes.";

print "Original: $text\n\n";
print "Getting 3 casual variations...\n";
print "=" x 60, "\n\n";

my $result = rewrite(
    text       => $text,
    mode       => 'casual',
    variations => 3,
    loop       => $loop,
)->get;

my $i = 1;
for my $var ($result->all_variations) {
    print "Variation $i:\n  $var\n\n";
    $i++;
}

print "Total variations: ", $result->variation_count, "\n";
