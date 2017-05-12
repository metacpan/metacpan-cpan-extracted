use strict;
use Text::PDF::File;
use Getopt::Std;

our ($opt_g, $opt_n, $opt_o);
getopt("g:n:o:");

unless (defined $ARGV[0])
{
    die <<'EOT';
    PDFGETOBJ [-g gen] -n num [-o outfile] pdffile
    Gets the given object from the pdf file and unpacks it to either stdout
or outfile.

    -g gen      Generation number [0]
    -n num      Object number
    -o outfile  Output file
EOT
}

my ($file, $offset, $res, $str);

$file = Text::PDF::File->open("$ARGV[0]") || die "Unable to open $ARGV[0]";
$offset = $file->locate_obj($opt_n, $opt_g) || die "Can't find obj $opt_n $opt_g";
seek($file->{' INFILE'}, $offset, 0);
($res, $str) = $file->readval("");

if (defined $opt_o)
{
    open(OUTFILE, ">$opt_o") || die "Unable to open $opt_o";
    binmode OUTFILE;
    select OUTFILE;
}


if (defined $res->{' stream'})
{
    print $res->read_stream(1)->{' stream'};
} else
{
    print $res->val;
}

close(OUTFILE) if defined $opt_o;

