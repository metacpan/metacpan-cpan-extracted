#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../";
use VCS;
use Getopt::Long;
use File::Basename;

my $opt_recurse = 0;
GetOptions('recurse' => \$opt_recurse);

my $dir = $ARGV[0] || die <<EOF;
Usage: $0 dir
    or $0 -recurse dir
EOF

$dir =~ s#/*$##;
chdir dirname $dir;
$dir = basename $dir;

show($dir, 0);

sub show {
    my($dir, $depth) = @_;
#warn "show: $dir, $depth\n";
    my $d = VCS::Dir->new($dir);
    unless (defined $d) {
        print "Not a VCS::Dir: $dir\n";
        return;
    }
#warn "got: $d\n";
    disp($d, $depth);
    foreach my $x ($d->content) {
        if ($opt_recurse && (ref($x) =~ /::Dir$/)) {
            show($x->path, $depth+1);
        } else {
            disp($x, $depth+1);
        }
    }
}

sub disp {
    my ($obj, $depth) = @_;
#warn "HERE\n";
    print
        "\t" x $depth,
        $obj->path,
        "\t",
        ref($obj),
        "\n",
        ;
}
