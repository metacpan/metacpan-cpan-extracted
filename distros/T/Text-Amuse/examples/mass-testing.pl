#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use File::Find;
use Path::Tiny;
use Data::Dumper::Concise;
use lib "$FindBin::Bin/../lib";
use Text::Amuse;
binmode STDOUT, ":encoding(UTF-8)";
binmode STDERR, ":encoding(UTF-8)";

my ($in, $out) = @ARGV;
die "Missing arguments input and output directory" unless $in && $out;

print "Using Text::Amuse $Text::Amuse::VERSION\n";
die "$in is not a dir" unless -d $in;
die "$out is not a dir" unless -d $out;

my %files;
find(sub {
         if (-f $_ and $File::Find::name =~ m/\.muse$/) {
             my $file = $File::Find::name;
             $file =~ s/\A\Q$in\E//;
             $file =~ s/\.muse\z//;
             $file =~ s/\//-/g;
             $files{$File::Find::name} = $file;
         }
     }, $in);

my $start = time();
my $count = 0;
foreach my $file (sort keys %files) {
    my $muse = Text::Amuse->new(file => $file);
    $count++;
    foreach my $fmt (qw/latex html/) {
        my $out = path($out, $files{$file} . '.' . $fmt);
        my $m = "as_$fmt";
        print "Producing $out\n";
        $out->spew_utf8($muse->$m);
    }
}
my $stop = time();
print "Using Text::Amuse $Text::Amuse::VERSION\n";
print "Total running time ($count files): " . ($stop - $start) . "\n";

     
           
