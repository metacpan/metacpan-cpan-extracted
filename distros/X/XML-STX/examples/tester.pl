#!/usr/bin/perl
BEGIN {
    unshift @INC, "blib/lib", "blib/arch", "test";
}

use strict;
use XML::STX;
use TestHandler;

(@ARGV == 2 ) || die ("Usage: tester.pl stylesheet.stx data.xml\n\n");

my $templ_uri = shift;
my $data_uri = shift;

my $stx = XML::STX->new(Writer => 'XML::STX::Writer');
my $transformer = $stx->new_transformer($templ_uri);

my $source = $stx->new_source($data_uri);
my $handler = TestHandler->new();
my $result = $stx->new_result($handler);

$transformer->transform($source, $result);

print "$handler->{result}\n";

exit 0;
