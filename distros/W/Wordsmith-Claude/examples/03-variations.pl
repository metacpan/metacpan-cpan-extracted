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

my $text = "I apologize for the inconvenience. We are working to resolve this issue as quickly as possible.";

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
