#!/usr/bin/env perl

use Modern::Perl;
use Getopt::Std;
use Path::Tiny;

# get arguments
getopts("o:", \my %opts);
@ARGV==1 or die "Usage: t2p [-o output.p] input.bas\n";
my $bas_file = shift;
my $p_file = $opts{o} ? $opts{o} : ($bas_file =~ s/\.\w+$/.p/r);
-f $bas_file or die "file not found: $bas_file\n";
$bas_file eq $p_file and die "output file same as input file\n";

# call t2p
system("t2p -o $p_file $bas_file")==0 or die "t2p failed\n";

# patch the result file
my @bytes = map {ord} split //, path($p_file)->slurp_raw;

# remove last 0x76 byte from $p_file
pop @bytes;

# make FRAMES = FFFF
$bytes[0x4034-0x4009] = 0xFF;
$bytes[0x4035-0x4009] = 0xFF;

# make CH_ADD = E_LINE+1
my $e_line = $bytes[0x4014-0x4009] | ($bytes[0x4015-0x4009] << 8);
my $ch_add = $e_line + 1;
$bytes[0x4016-0x4009] = $ch_add & 0xFF;
$bytes[0x4017-0x4009] = ($ch_add >> 8) & 0xFF;

# make STKBOT = STKTOP = CH_ADD+1
my $stkbot = $ch_add + 1;
$bytes[0x401A-0x4009] = $stkbot & 0xFF;
$bytes[0x401B-0x4009] = ($stkbot >> 8) & 0xFF;
$bytes[0x401C-0x4009] = $stkbot & 0xFF;
$bytes[0x401D-0x4009] = ($stkbot >> 8) & 0xFF;

# write the file
path($p_file)->spew_raw(join '', map {chr} @bytes);
