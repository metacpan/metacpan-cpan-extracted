#!/usr/bin/perl
use strict;
use Test::Simple tests => 7;

use Text::PDF::File;
use Text::PDF::Page;        # pulls in Pages
use Text::PDF::Utils;       # not strictly needed
use Text::PDF::SFont;

my ($testpdf) = 't/temp.pdf';
my ($testdata) = 'BT 1 0 0 1 250 600 Tm /F0 14 Tf (Hello World!) Tj ET';

unlink($testpdf);
ok(!(-f $testpdf), 'verify pdf does not pre-exist');

# Create a Hello world PDF

my ($pdf, $root, $page, $font);

$pdf = Text::PDF::File->new;            # Make up a new document
$root = Text::PDF::Pages->new($pdf);    # Make a page tree in the document
$root->proc_set("PDF", "Text");         # Say that all pages have PDF and Text instructions
$root->bbox(0, 0, 595, 840);            # hardwired page size A4 (for this app.) for all pages
$page = Text::PDF::Page->new($pdf, $root);      # Make a new page in the tree

$font = Text::PDF::SFont->new($pdf, 'Helvetica', 'F0');     # Make a new font in the document
$root->add_font($font);                                     # Tell all pages about the font

$page->add($testdata);        # put some content on the page
$pdf->out_file($testpdf);   # output the document to a file
$pdf->release;

ok(-f $testpdf, "write temporary file $testpdf");

# Now try to read the PDF

my ($file, $offset, $res, $str);

$file = Text::PDF::File->open($testpdf);
ok($file, 'open pdf');
$offset = $file->locate_obj(5, 0);
ok($offset, 'find object');
seek($file->{' INFILE'}, $offset, 0);
($res, $str) = $file->readval("");
ok(defined($res->{' stream'}), 'got stream');
my ($data) = $res->read_stream(1)->{' stream'};
$file->release;
$data =~ s/\s+$//;
ok( $data eq $testdata, 'correct content');

# Finally make sure we can delete the PDF

unlink($testpdf);
ok(!(-f $testpdf), "delete temporary file $testpdf");

# all done!

