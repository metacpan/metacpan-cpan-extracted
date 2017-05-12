#!/usr/bin/perl -w

# Use DATA_MODE and DATA_INDENT to make data documents easier to read

use strict;

use XML::Writer;
use IO::File;

my $writer = XML::Writer->new(DATA_MODE => 1, DATA_INDENT => 2);
$writer->startTag("doc");
$writer->startTag("x");
$writer->dataElement("y", "Hello, world!");
$writer->dataElement("y", "Hello, world!");
$writer->endTag("x");
$writer->startTag("x");
$writer->dataElement("y", "Hello, world!");
$writer->dataElement("y", "Hello, world!");
$writer->endTag("x");
$writer->endTag("doc");
$writer->end();
