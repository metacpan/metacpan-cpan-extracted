#!perl

use strict;
use warnings;

use XUL::Image::PPT;
use Getopt::Long;

my ($help, $indir, $from);
GetOptions (
    'help'    => \$help,
    'indir=s' => \$indir,
    'from=i'  => \$from,
) or help(1);

help(0) if $help;

my $conv = XUL::Image::PPT->new(
    indir => $indir,
    from  => $from,
);
$conv->go;

sub help {
    my $code = shift;
    warn <<'_EOC_';
usage: img2ppt [options]

options:
    --help      print this message
    --indir s   use s as the image input directory
                (defaults to ./xul_img)
    --from i    set the index of the first PPT slide
                (defaults to 1)
_EOC_
    exit($code);
}
