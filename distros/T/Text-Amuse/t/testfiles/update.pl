#!/usr/bin/env perl
use strict;
use warnings;
use lib '../../lib';
use Text::Amuse;
use Getopt::Long;

my $beamer;
GetOptions (beamer => 1) or die;

foreach my $f (@ARGV) {
    next unless -f $f;
    if ($f =~ m/([[a-zA-Z0-9_-]+)\.muse$/) {
        my $amuse = Text::Amuse->new(file => $f);
        my $out = $1 . ".exp";
        write_file($out . ".html", $amuse->as_html);
        write_file($out . ".ltx", $amuse->as_latex);
        write_file($out . ".sl.tex", $amuse->as_beamer) if $beamer;
    }
}

sub write_file {
    my ($file, $string) = @_;
    warn "Writing out $file\n";
    open (my $fh, '>:encoding(utf-8)', $file) or die "$file: $!";
    print $fh $string;
    close $fh;
}
