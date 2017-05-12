#!/usr/bin/env perl
# Copyright (c) 2014, 2015 Yon <anaseto@bardinflor.perso.aquilenet.fr>
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

use utf8;
use v5.12;
use strict;
use warnings;
use open qw(:std :utf8);
use Test::More tests => 48;
use Text::Diff;
use lib 'lib';
use Text::Frundis;

my $DATA_DIR = "t/data";

die "$DATA_DIR: data directory not found\n" unless -d $DATA_DIR;

my $cmd = "";
if (@ARGV) {
    $cmd = $ARGV[0];
    if ($cmd eq "update") {
        shift @ARGV;
    }
}

my @files = @ARGV ? @ARGV : glob("$DATA_DIR/*.frundis");

my $output = ".frundis.out";

unless (-w ".") {
    die "current directory should be writable\n";
}

my $update = 0;
if ($cmd eq "update") {
    $update = 1;
}

my $frundis = Text::Frundis->new;

foreach my $file (@files) {
    process_file_format($file, "latex");
    process_file_format($file, "xhtml");
}

if (-f $output) {
    unlink $output;
}

sub process_file_format {
    my ($file, $format) = @_;
    my $suffix;
    if ($format eq "latex") {
        $suffix = "tex";
    }
    elsif ($format eq "xhtml") {
        $suffix = "html";
    }
    else {
       die "process_file_format: unknown format: $format\n"; 
    }

    $file =~ m/^(.*)\.frundis$/;
    my $basename = $1;

    SKIP: {
        skip 'command filtering test non portable on MSWin32', 1
          if $^O eq "MSWin32" and $file =~ /filters/;

        local $@;
        eval {
            $frundis->process_source(
                input_file => $file,
                all_in_one_file => 1,
                target_format => $format,
                output_file => $output,
                redirect_stderr => 1,
                use_carp => 0,
            );
        };
        if ($@) {
            ok(0, "$basename.$suffix");
            diag "Error while processing $file to $format: $@";
            return;
        }

        my $new = slurp($output);
        unless (-f "$basename.$suffix") {
            ok(0, "$basename.$suffix");
            diag $new;
            diag "No data test file found for format $format. ";
            if ($update) {
                local $| = 1;
                print "Put new? [Y/n] ";
                my $response = <STDIN>;
                chomp $response;
                if ($response eq "Y") {
                    print "creating $basename.$suffix\n";
                    rename $output, "$basename.$suffix";
                }
            }
            return;
        } 
        my $old = slurp("$basename.$suffix");
        my $diff = diff(\$new, \$old);
        if (not ok($diff eq "", "$basename.$suffix")) {
            diag("# Diff between new and old $basename.$suffix");
            diag($diff);
            if ($update) {
                local $| = 1;
                print "Data test file and program output differ for format $format. Put new? [Y/n] ";
                my $response = <STDIN>;
                chomp $response;
                if ($response eq "Y") {
                    print "replacing $basename.$suffix\n";
                    rename $output, "$basename.$suffix";
                }
            }
        }
    }
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
