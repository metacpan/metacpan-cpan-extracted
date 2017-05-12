#!/usr/bin/env perl
# Copyright (c) 2015 Yon <anaseto@bardinflor.perso.aquilenet.fr>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use strict;
use warnings;
use Test::More tests => 11;
use File::Path qw(remove_tree);
use File::Copy qw(move);
use File::DirCompare;
use Text::Diff;

use lib 'lib';
use Text::Frundis;

my $DATA_DIR = "t/data-dirs";

die "$DATA_DIR: data directory not found\n" unless -d $DATA_DIR;

my $cmd = "";
if (@ARGV) {
    $cmd = $ARGV[0];
    if ($cmd eq "update") {
        shift @ARGV;
    }
}

my @files = @ARGV ? @ARGV : glob("$DATA_DIR/*.frundis");
my $diff;

my $output = ".frundis-dir.out";

unless (-w ".") {
    die "current directory should be writable\n";
}

my $update = 0;
if ($cmd eq "update") {
    $update = 1;
}

my $frundis = Text::Frundis->new;

foreach my $file (@files) {
    if ($file =~ /-epub/) {
        process_file_format($file, "epub");
        next;
    }
    elsif ($file =~ /-xhtml/) {
        process_file_format($file, "xhtml");
        process_file_format($file, "xhtml", 1);
        next;
    }
    elsif ($file =~ /-latex/) {
        process_file_format($file, "latex", 1);
        next;
    }

    process_file_format($file, "epub");
    process_file_format($file, "xhtml");
    process_file_format($file, "xhtml", 1);
    process_file_format($file, "latex", 1);
}

sub process_file_format {
    my ($file, $format, $to_file) = @_;
    my $suffix;
    if ($format eq "epub") {
        $suffix = "-epub";
    }
    elsif ($format eq "xhtml") {
        if ($to_file) {
            $suffix = ".html";
        }
        else {
            $suffix = "-html";
        }
    }
    elsif ($format eq "latex") {
        $suffix = ".tex";
    }
    else {
       die "process_file_format: unknown format: $format\n"; 
    }

    $file =~ m/^(.*)\.frundis$/;
    my $basename = $1;
    if (-d $output) {
        remove_tree($output) or die $!;
    }
    if (-f $output) {
        unlink $output or die $!;
    }

    local $@;
    eval {
        if ($to_file) {
            $frundis->process_source(
                input_file => $file,
                all_in_one_file => 1,
                target_format => $format,
                standalone => 1,
                output_file => $output,
            );
        }
        else {
            $frundis->process_source(
                input_file => $file,
                target_format => $format,
                output_file => $output,
            );
        }
    };
    SKIP: {
        if ($@) {
            ok(0, "$basename$suffix");
            diag "Error while processing $file to $format: $@";
            return;
        }
        unless (-e "$basename$suffix") {
            ok(0, "$basename$suffix");
            diag "No data test directory found for format $format. ";
            if ($update) {
                print "Put new? [Y/n] ";
                my $response = <STDIN>;
                chomp $response;
                if ($response eq "Y") {
                    print "creating $basename$suffix\n";
                    move($output, "$basename$suffix") or die $!;
                }
            }
            return;
        } 
        my $ok = 1;
        if (-d "$basename$suffix") {
            File::DirCompare->compare("$basename$suffix", $output, sub {
                my ($f1, $f2) = @_;
                if (! $f1) {
                    $ok = 0;
                    diag("# $f2 shouldn't exist. Contents:\n");
                    diag(slurp($f2));
                }
                elsif (! $f2) {
                    $ok = 0;
                    diag("# no $f1 found in test output under $output. Contents:\n");
                    diag(slurp($f1));
                }
                else {
                    my $diff = diff($f1, $f2);
                    if ($diff ne "") {
                        $ok = 0;
                        diag("# Files $f1 and $f2 differ:\n");
                        diag($diff);
                    }
                }
            });
        }
        else {
            my $diff = diff("$basename$suffix", $output);
            if ($diff ne "") {
                $ok = 0;
                diag("# Files $basename$suffix and $output differ:\n");
                diag($diff);
            }
        }
        if (not (ok($ok, "$basename$suffix"))) {
            diag "Difference between gotten and expected for $basename$suffix\n";
            if ($update) {
                print "Data test directory and program output differ for format $format. Put new? [Y/n] ";
                my $response = <STDIN>;
                chomp $response;
                if ($response eq "Y") {
                    print "replacing $basename$suffix\n";
                    remove_tree("$basename$suffix") or die "remove_tree:$!";
                    move($output, "$basename$suffix") or die "move:$!";
                }
            }
        }
    }
}
if (-d $output) {
    remove_tree($output) or die $!;
}
if (-f $output) {
    unlink $output or die $!;
}

sub slurp {
    my $file = shift;
    open(my $fh, '<', $file) or die "$file:$!";
    local $/;
    my $text = <$fh>;
    close $fh;
    return $text;
}

done_testing();

# vim:sw=4:sts=4:expandtab
