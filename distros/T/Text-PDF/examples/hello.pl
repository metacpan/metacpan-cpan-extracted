#
# An example program which prints Hello World! on a page
#

use Text::PDF::File;
use Text::PDF::Page;        # pulls in Pages
use Text::PDF::Utils;       # not strictly needed
use Text::PDF::SFont;

$pdf = Text::PDF::File->new;            # Make up a new document
$root = Text::PDF::Pages->new($pdf);    # Make a page tree in the document
$root->proc_set("PDF", "Text");         # Say that all pages have PDF and Text instructions
$root->bbox(0, 0, 595, 840);            # hardwired page size A4 (for this app.) for all pages
$page = Text::PDF::Page->new($pdf, $root);      # Make a new page in the tree

$font = Text::PDF::SFont->new($pdf, 'Helvetica', 'F0');     # Make a new font in the document
$root->add_font($font);                                     # Tell all pages about the font

$page->add("BT 1 0 0 1 250 600 Tm /F0 14 Tf (Hello World!) Tj ET");        # put some content on the page
# $page->add(" BT 1 0 0 1 250 700 Tm /F0 14 Tf (Hello World line two!) Tj ET");
# $page->{' curstrm'}{'Filter'} = PDFArray(PDFName('FlateDecode'));       # compress the page content
$pdf->out_file($ARGV[0]);   # output the document to a file

# all done!

