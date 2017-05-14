#!/usr/bin/perl -w
use strict;

while (<>) {
    chomp;
    my $f = $_;
    my @path = split(/\//, $f);
    my $lf = pop @path;
    next unless $lf;
    if ($lf =~ /(.*)\.(\S+)$/) {
        my $n = $1;
        my $sfx = $2;
        if ($sfx eq 'pm' || $sfx eq 'pl' || $sfx eq 'pod') {
            print STDERR "Making pod for $lf\n";
            my $dir = join('/', 'pod', @path);
            my $title = 
              join('::',@path,$n);
            `mkdir -p $dir` unless -d $dir;
            my $outf = $dir . '/'. $n . '.html';
            my $tmpf = "tmp";
            open(OF,">$tmpf") || die ("can't open $tmpf");
            open(F, $f) || die ("cannot open file:$f");
            while(<F>) {
                s/L\<(map2slim|go2\w+|\w+)(\.pl|)\>/L\<scripts::$1\>/g;
                print OF $_;
            }
            close(F);
            close(OF);
            system("pod2html --htmlroot /dev/pod --title $title $tmpf > $outf");
        }
    }
    elsif (@path && $path[-1] eq 'scripts') {
        print STDERR "Making pod for $lf\n";
        my $dir = join('/', 'pod', @path);
        my $title = 
          join('::',@path,$lf);
        `mkdir -p $dir` unless -d $dir;
        my $outf = $dir . '/'. $lf . '.html';
        system("pod2html --htmlroot /dev/pod --title $title $f > $outf");

    }
    else {
    }
}
