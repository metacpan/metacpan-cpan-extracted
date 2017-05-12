#!/usr/bin/perl
use warnings;
use strict;

use XML::Writer;
use XML::Writer::String;

my $s = XML::Writer::String->new();
my $writer = new XML::Writer( OUTPUT => $s,
  DATA_MODE => 1, DATA_INDENT => 4);

$writer->xmlDecl();
$writer->startTag('module', name=>'XML::Writer::String');
$writer->dataElement('abstract', 'Capture output from XML::Writer');
$writer->dataElement('author', 'S. Oliver <simon.oliver@umist.ac.uk>');
$writer->endTag();
$writer->end();

print $s->value();
