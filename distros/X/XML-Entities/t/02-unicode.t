#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    use_ok('XML::Entities');
}

my $VERBOSE = 0;

my $e = "p&#345;&#237;&#353;t&#237;";
my ($d) = XML::Entities::decode('all', $e);

my ($t, $T);
{
    use utf8;
    $t = 'příští';
    $T = 'PŘÍŠTÍ';
}
is($d, $t, q{Encoded fine});
is(uc($d), $T, q{Upcased fine});
my @c = split //, $d;
is(scalar(@c), 6, q{Split in the right number of characters});

if ($VERBOSE) {
    use open qw(:std :utf8);
    print "I got string '$e'.\n";
    print "I decoded it to '$d'.\n";
    print "Then upcased it to '", uc($d), "'.\n";
    print "And split it to characters:\n";
    print "$_\n" for @c;
}
