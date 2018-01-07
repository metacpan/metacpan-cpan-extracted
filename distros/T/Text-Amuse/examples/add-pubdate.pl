#!/usr/bin/env/perl

use strict;
use warnings;
use Data::Dumper;
use File::Find;
use Path::Tiny;
use Text::Amuse::Functions qw/muse_fast_scan_header muse_rewrite_header/;

my @repos = @ARGV;

my @changes;

foreach my $repo (@repos) {
    my @files;
    find(sub {
             my $f = $_;
             if (-f $f and $f =~ m/\A[a-z0-9][a-z0-9-]*\.muse\z/) {
                 my $header = muse_fast_scan_header($f);
                 unless ($header->{pubdate}) {
                     my $date = `git log --follow -n 1 --format="\%ci" --diff-filter=A $f`;
                     chomp $date;
                     if ($date) {
                         muse_rewrite_header($f, { pubdate => $date })
                     }
                 }
             }
         }, path($repo)->children(qr{\A[a-z0-9]\z}));
}

