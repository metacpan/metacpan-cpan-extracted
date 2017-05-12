#!/usr/bin/perl -w

# Write a simple XML document to a file

use strict;

use XML::Writer;

my $output;

open($output, '>', 'output.xml') or die "Unable to open output file: $!";

my $writer = XML::Writer->new(OUTPUT => $output);
$writer->startTag("greeting",
                  "class" => "simple");
$writer->characters("Hello, world!");
$writer->endTag("greeting");
$writer->end();
close($output) or die "Failed to close output file: $!";
