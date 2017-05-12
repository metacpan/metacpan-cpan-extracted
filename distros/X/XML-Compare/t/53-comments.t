#!/usr/bin/perl

use strict;
use warnings;
use Test::XML::Compare tests => 1;

my $tests = [
   {
       name => 'Comment Ignored',
       xml1 => '<foo></foo>',
       xml2 => '<foo><!-- Comment --></foo>',
   },
];

foreach my $t ( @$tests ) {
    is_xml_same($t->{xml1}, $t->{xml2}, $t->{name});
}
