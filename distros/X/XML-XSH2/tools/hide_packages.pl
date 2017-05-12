#!/usr/bin/perl

# $Id: gen_pod.pl,v 2.3 2007-01-02 22:03:21 pajas Exp $

use strict;
use warnings;

if (!@ARGV or $ARGV[0] =~ /^(-h|--help)?$/) {
    print << "EOF";
Hides internal packages (not containing Prefix) from the PAUSE indexer.

Usage: $0 Module.pm Prefix

EOF
    exit;
}

my ($file, $prefix) = @ARGV;

open my $IN,  '<', $file          or die $!;
open my $OUT, '>', $file . '.new' or die $!;

while (<$IN>) {
    if (my ($pkg_or_ver, $name) = /^ \s* ( package | our \s* \$VERSION \s* = ) \s+ (.*?) \s* ; /x) {
        s/\Q$pkg_or_ver/$pkg_or_ver # Hide from PAUSE\n    /
            unless 'package' eq $pkg_or_ver and $name =~ /^$prefix/;
    }
    print {$OUT} $_;
}
close $OUT or die $!;
close $IN  or die $!; # MSWin
rename "$file.new", $file or die $!;
