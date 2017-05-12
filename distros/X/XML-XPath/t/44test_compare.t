#!/usr/bin/perl

use strict;
use warnings;
use XML::XPath;
use Test::More;

my $xml='<root att="root_att"><daughter att="3"/><daughter att="4"/><daughter att="5"/></root>';
my %results= ( '/root/daughter[@att<"4"]' => 'daughter[3]',
               '/root/daughter[@att<4]'   => 'daughter[3]',
               '//daughter[@att<4]'       => 'daughter[3]',
               '/root/daughter[@att>4]'   => 'daughter[5]',
               '/root/daughter[@att>5]'   => '',
               '/root/daughter[@att<3]'   => '',
             );

plan tests => scalar keys %results;

my $xpath  = XML::XPath->new( xml => $xml);
foreach my $path ( keys %results) {
    my @xpath_result = $xpath->findnodes( $path);
    is( dump_nodes( @xpath_result) => $results{$path}, "path: $path");
}

sub dump_nodes {
    return join '-', map { $_->getName . "[" . $_->getAttribute( 'att') . "]" } @_
}
