use Text::PDF::File;
use Getopt::Std;

getopts("g:m:n:");

unless(defined $opt_n && defined $ARGV[1])
{
    die <<'EOT';
    pdfaddobj [-g gen] [-m num] -n num pdf_file data_file
Adds the given file as object number given by -n to pdf_file.

    -g gen      Generation number of -n to insert
    -m num      Font hack. Lookup object -m and add a reference
                to -n as FontFile2 in that dictionary
    -n num      Object number to insert/replace as
EOT
}

$f = Text::PDF::File->open($ARGV[0], 1) || "Can't open $ARGV[0]";
$res = $f->read_objnum($opt_n, $opt_g);

open(INFILE, $ARGV[1]) || die "Can't read $ARGV[1]";
binmode(INFILE);
$res->{' stream'} = "";
while (read(INFILE, $dat, 4096))
{ $res->{' stream'} .= $dat; }
delete $res->{' nofilt'};
$res->{'Length1'}
$f->out_obj($res);

if (defined $opt_m)
{
    $mres = $f->read_objnum($opt_m, 0);
    $mres->{'FontFile2'} = $res;
    $f->out_obj($mres);
}
$f->append_file;


