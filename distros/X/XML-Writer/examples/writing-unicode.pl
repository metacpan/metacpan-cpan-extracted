#!/usr/bin/perl -w

# Generate UTF-8 output of a Unicode string

use strict;

use XML::Writer;

my $unicodeString = "\x{201C}This\x{201D} is a test - \$ \x{00A3} \x{20AC}";

my $w = XML::Writer->new(ENCODING => 'utf-8');

$w->xmlDecl();

$w->startTag('doc');
$w->characters($unicodeString);
$w->endTag('doc');
$w->end();
