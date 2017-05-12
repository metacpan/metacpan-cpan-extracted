#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;
use XML::Compare;

# $XML::Compare::VERBOSE = 1;

my $same = [
   {
       name => 'Comment Ignored',
       xml1 => '<foo></foo>',
       xml2 => '<foo><!-- Comment --></foo>',
   },
];

my $diff = [
   {
       name => 'Comment Ignored (therefore different number of children)',
       xml1 => '<foo><child /></foo>',
       xml2 => '<foo><!-- Comment --></foo>',
       error => qr{different number of child nodes},
   },
];

foreach my $t ( @$same ) {
    lives_ok{ XML::Compare::same($t->{xml1}, $t->{xml2}) } $t->{name};
}

foreach my $t ( @$diff ) {
    throws_ok{ XML::Compare::same($t->{xml1}, $t->{xml2}) } $t->{error}, $t->{name};
}
