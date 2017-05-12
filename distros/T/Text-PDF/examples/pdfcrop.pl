use Text::PDF::File;
use Text::PDF::Utils;
use IO::File;
use Getopt::Std;

getopts('c:l:p:t:');

unless (-f $ARGV[0] && $opt_c)
{
    die <<'EOT';
    pdfcrop -c config.dat [-l length] [-t thickness] [-p num[,num...]] file
    Adds crop marks to a PDF file as specified in the configuartion file.
Default values of arm length and thickness can be overridden on the command
line and crop marks only added to certain pages.

    -c config.dat   Configuration file [required]
    -l length       Arm length in pts [default from config file]
    -p pagelist     List of page numbers, comma separated
    -t thickness    Arm width in pts [default from config file]

The config file takes the following format:
    length = 36
    thickness = .5
    ;# or anything unrecognised is a comment
    100, 100    sw
    485, 100    se
    765, 100    nw
    765, 485    ne
The n, s, e, w indicate which arms to display for each crop mark. Locations
are in points.
EOT
}

@opt_p = split(/\D\s*/, $opt_p) if ($opt_p);
$content = make_content($opt_c, $opt_l, $opt_t);

$pdf = Text::PDF::File->open($ARGV[0], 1);
$root = $pdf->{'Root'}->realise;
$pgs = $root->{'Pages'}->realise;

$stream = PDFDict();
$stream->{' stream'} = $content;
$stream->{'Filter'} = PDFArray(PDFName('FlateDecode'));
$pdf->new_obj($stream);

@pglist = proc_pages($pdf, $pgs);

$j = 0;
for ($i = 0; $i <= $#pglist; $i++)
{
    next unless ($i == $opt_p[$j] || !defined $opt_p);
    $j++;
    $p = $pglist[$i];
    $p->{'Contents'} = PDFArray($stream, $p->{'Contents'}->elementsof);
    $pdf->out_obj($p);
}

$pdf->close_file;

sub proc_pages
{
    my ($pdf, $pgs) = @_;
    my ($pg, $pgref, @pglist);

    foreach $pgref ($pgs->{'Kids'}->elementsof)
    {
        $pg = $pdf->read_obj($pgref);
        if ($pg->{'Type'}->val =~ m/^Pages$/oi)
        { push(@pglist, proc_pages($pdf, $pg)); }
        else
        {
            $pgref->{' pnum'} = $pcount++;
            push (@pglist, $pgref);
        }
    }
    (@pglist);
}

sub make_content
{
    my ($config, $length, $thick) = @_;
    my ($fh) = IO::File->new("< $config") || die "Can't open $config";
    my ($res);

    while (<$fh>)
    {
        if (m/^\s*length\s*=\s*([0-9.]+)/oi)
        { $length = $1 unless defined $length; }
        elsif (m/^\s*thickness\s*=\s*([0-9.]+)/oi)
        { $thick = $1 unless defined $thick; }
        if (s/\s*([0-9.]+)\s*,\s*([0-9.]+)\s+//o)
        {
            my ($x, $y) = ($1, $2);
            while (s/^([nsewtblr])\s*//oi)
            {
                my ($l, $t, $d) = ($length, $thick, lc($1));
                my ($xn, $yn) = ($x, $y);

# insert code for arm properties here

                if ($d eq 'n' || $d eq 't')
                { $yn += $l; }
                elsif ($d eq 's' || $d eq 'b')
                { $yn -= $l; }
                elsif ($d eq 'e' || $d eq 'r')
                { $xn += $l; }
                elsif ($d eq 'w' || $d eq 'l')
                { $xn -= $l; }
                
                $res .= "$t w $x $y m $xn $yn l S\n";
            }
        }
    }
    $res;
}

__END__
:endofperl
