#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;
use XML::Compare;

# $XML::Compare::VERBOSE = 1;

my $same = [
   {
       name => 'Comment Ignored',
       xml1 => '<foo></foo>',
       xml2 => '<foo><!-- Comment --></foo>',
   },
];

my $diff = [];

foreach my $t ( @$same ) {
    ok( XML::Compare::is_same($t->{xml1}, $t->{xml2}), $t->{name} );
}

foreach my $t ( @$diff ) {
    ok( XML::Compare::is_different($t->{xml1}, $t->{xml2}), $t->{name} );
}
