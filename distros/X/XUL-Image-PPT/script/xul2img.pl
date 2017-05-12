#!perl

use strict;
use warnings;

use XUL::Image;
use Getopt::Long;

my ($help, $outdir, $count, $title, $delay, $reset);
GetOptions (
    'help'      => \$help,
    'outdir=s'  => \$outdir,
    'count=i'   => \$count,
    'title=s'   => \$title,
    'delay=f'   => \$delay,
    'reset'     => \$reset,
) or help(1);

help(0) if $help;

if (!$count) {
    die "You must specify the slide count via the --count option.\n";
}

my $conv = XUL::Image->new(
    outdir => $outdir,
    count  => $count,
    title  => $title,
    delay  => $delay,
);
$conv->go(reset => $reset);

sub help {
    my $code = shift;
    warn <<'_EOC_';
usage: xul2img [options]

options:
    --help      print this message
    --outdir s  use s as the output directory
                (defaults to ./xul_img)
    --count i   set the count of slides
    --title s   set the slide title
                (a substring is okay)
    --reset     whether reset the slides to the
                first page.
_EOC_
    exit($code);
}
