#
# An example program which creates graph paper. Very simple, but shows the basics
# page creation, etc.

use Text::PDF::File;
use Text::PDF::Page;
use Text::PDF::Utils;

use Getopt::Std;

getopts('d:g:p:s:');

unless(defined $ARGV[0])
{
    die <<'EOT';
    GRAPH [-d size] [-g num] [-p num] [-s num] outfile
Generates graph paper as a PDF file to outfile.

    -d size     grid size in pts [8]
    -g percent  percentage black [100]
    -p num      primary (thick) lines every num lines [10]
    -s num      secondary (somewhat thick) lines every num lines [5]

EOT
}

$opt_d = 8 unless $opt_d;
$opt_g = 100 unless $opt_g;
$opt_g = 1. - $opt_g / 100.;
$opt_p = 10 unless defined $opt_p;
$opt_s = 5 unless defined $opt_s;

$pdf = Text::PDF::File->new;
$root = Text::PDF::Pages->new($pdf);
$root->proc_set("PDF");
$root->bbox(0, 0, 595, 840);            # hardwired page size A4 (for this app.)
$page = Text::PDF::Page->new($pdf, $root);

# Now pretend to make a simple font:
# $font = Text::PDF::SFont->new($pdf, 'Helvetica', 'F0');
# $root->add_font($font);
# Use same principle for other fonts. Could use $page->add_font($font) just as well.

# OK Now put something on this exciting page!

# assume 58 pt margin

$max_x = int(479 / $opt_d) * $opt_d + 58;
$max_y = int(724 / $opt_d) * $opt_d + 58;

$page->add("$opt_g G ");
$i = 0;
$curx = 58;
while ($curx <= 537)
{
    if ($opt_p and $i % $opt_p == 0)
    { $width = 1; }
    elsif ($opt_s and $i % $opt_s == 0)
    { $width = .5; }
    else
    { $width = .25; }

# No fancy interface for drawing. You create your own PDF code!    
    $page->add("$width w $curx 58 m $curx $max_y l S\n");
    
    $curx += $opt_d;
    $i++;
}

$i = 0;
$cury = 58;
while ($cury <= 782)
{
    if ($opt_p and $i % $opt_p == 0)
    { $width = 1; }
    elsif ($opt_s and $i % $opt_s == 0)
    { $width = .5; }
    else
    { $width = .25; }
    $page->add("$width w 58 $cury m $max_x $cury l S\n");
    $cury += $opt_d;
    $i++;
}

# Only now that something has been added can we mess with the content stream
$page->{' curstrm'}{'Filter'} = PDFArray(PDFName('FlateDecode'));
$pdf->out_file($ARGV[0]);

