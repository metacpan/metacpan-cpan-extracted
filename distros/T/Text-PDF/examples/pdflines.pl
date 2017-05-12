#
# An example program which creates graph paper. Very simple, but shows the basics
# page creation, etc.

use Text::PDF::File;
use Text::PDF::Page;
use Text::PDF::Utils;
use IO::File;

use Getopt::Std;

getopts('c:m:n:p:s:');

unless(defined $ARGV[0] && $opt_c)
{
    die <<'EOT';
    GRAPH [-M left,bottom,right,top] [-n num] [-p num] [-s size] -c config.dat outfile
Generates graph paper as a PDF file to outfile.

    -c data file        Configuration file
    -M num,num,num,num  Margins in points [56,56,56,56]
    -n num              Number of line blocks to fit or 0 for no flexibility
    -p num              Only generate page number num
    -s size             either one of (A4,ltr,lgl,A3,A5) or
                            width,height
Config file:
\width pts              Height in points of one line block
\line  pts [string]     relative to bottom of block, PDF string (optional)
\line  ...
EOT
}

%sizes = (
    'a3' => [840, 1190],
    'a4' => [595, 840],
    'a5' => [420, 595],
    'ltr' => [612, 792],
    'lgl' => [792, 1008],
    
    'a3l' => [1190, 840],
    'a4l' => [840, 595],
    'a5l' => [595, 420],
    'ltrl' => [792, 612],
    'lgll' => [1008, 792]
    );

$opt_m = "56,56,56,56" unless $opt_m;
$opt_s = 'A4' unless $opt_s;

process($opt_c) || die "Can't process $opt_c";

if (defined $sizes{lc($opt_s)})
{ @opt_s = @{$sizes{lc($opt_s)}}; }
else
{ @opt_s = split(/,\s*/, $opt_s); }

@opt_m = split(/,\s*/, $opt_m);

$pdf = Text::PDF::File->new;
$root = Text::PDF::Pages->new($pdf);
$root->proc_set("PDF");
$root->bbox(0, 0, @opt_s);

# Now pretend to make a simple font:
# $font = Text::PDF::SFont->new($pdf, 'Helvetica', 'F0');
# $root->add_font($font);
# Use same principle for other fonts. Could use $page->add_font($font) just as well.

# OK Now put something on this exciting page!

$height = $opt_s[1] - $opt_m[1] - $opt_m[3];
$farr = $opt_s[0] - $opt_m[2];

if (defined $opt_p)
{
    $first = $opt_p;
    $last = $opt_p;
} else
{
    $first = 0;
    $last = scalar @widths;
}

for ($pcount = $first; $pcount < $last; $pcount++)
{
    $page = Text::PDF::Page->new($pdf, $root);
    $width = $widths[$pcount];
    if ($opt_n eq '0')
    {
        $gap = 0;
    } else
    {
        $opt_n = int($height / $width) unless $opt_n;
        $gap = ($height - $opt_n * $width) / ($opt_n - 1);
    }
    
    for ($y = $opt_m[1]; $y <= $height + $opt_m[3]; $y += $width + $gap)
    {
        foreach $l (@{$lines[$pcount]})
        {
            $offy = $l->[0] + $y;
            $page->add(sprintf("%s %d %.2f m %d %.2f l S\n", 
                $l->[1], $opt_m[0], $offy, $farr, $offy));
        }
    }
#    $page->{' curstrm'}{'Filter'} = PDFArray(PDFName('FlateDecode'));
}

# Only now that something has been added can we mess with the content stream
$pdf->out_file($ARGV[0]);

sub process
{
    my ($fname) = @_;
    my ($fh) = IO::File->new("< $fname") || return undef;
    my ($width, $pcount);
    
    $pcount = -1;
    while (<$fh>)
    {
        if (m/^\\width\s+([0-9.]+)/o)
        {   
            $pcount++;
            $widths[$pcount] = $1; 
        }
        elsif (m/^\\line\s+([0-9.]+)(?:\s+(.*?)\s*$)?/o)
        { 
            my ($pos) = $1;
            my ($str) = $2 || '[] 0 d .25 w 0 g';
            push (@{$lines[$pcount]}, [$pos, $str]); 
        }
    }
    1;
}
