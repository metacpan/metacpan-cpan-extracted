#!/usr/bin/env perl

use Modern::Perl;
use Getopt::Std;
use Path::Tiny;

# get arguments
getopts( "o:", \my %opts );
@ARGV == 1 or die "Usage: t2p [-o output.p] input.bas\n";
my $bas_file = shift;
my $p_file   = $opts{o} ? $opts{o} : ( $bas_file =~ s/\.\w+$/.p/r );
-f $bas_file or die "file not found: $bas_file\n";
$bas_file eq $p_file and die "output file same as input file\n";

# patch source file to make it compatible with t2p
my $source = path($bas_file)->slurp;

# replace @label: 10 PRINT by 10 @label: PRINT
$source =~ s/^(\s*\@\w+:)(\s*\d+\s*)/$2 $1/mg;

# load AUTOSTART and AUTOSTART_LINE pragmas
my $AUTOSTART      = 0;
my $AUTOSTART_LINE = 0;
while ( $source =~ /^\s*\#\s*AUTOSTART\s*=\s*(\d+)/mg ) {
    $AUTOSTART = !!$1;
}
while ( $source =~ /^\s*\#\s*AUTOSTART_LINE\s*=\s*(\d+)/mg ) {
    $AUTOSTART_LINE = $1;
}

# save patched source to a temporary file
path("$bas_file.2")->spew($source);

# call t2p
system("t2p -o $p_file $bas_file.2") == 0 or die "t2p failed\n";
unlink "$bas_file.2";

# patch the result file
my @bytes = map { ord } split //, path($p_file)->slurp_raw;

# remove last 0x76 byte from $p_file
pop @bytes;

# make FRAMES = FFFF
$bytes[ 0x4034 - 0x4009 ] = 0xFF;
$bytes[ 0x4035 - 0x4009 ] = 0xFF;

# make CH_ADD = E_LINE+1
my $e_line = $bytes[ 0x4014 - 0x4009 ] | ( $bytes[ 0x4015 - 0x4009 ] << 8 );
my $ch_add = $e_line + 1;
$bytes[ 0x4016 - 0x4009 ] = $ch_add & 0xFF;
$bytes[ 0x4017 - 0x4009 ] = ( $ch_add >> 8 ) & 0xFF;

# make STKBOT = STKTOP = CH_ADD+1
my $stkbot = $ch_add + 1;
$bytes[ 0x401A - 0x4009 ] = $stkbot & 0xFF;
$bytes[ 0x401B - 0x4009 ] = ( $stkbot >> 8 ) & 0xFF;
$bytes[ 0x401C - 0x4009 ] = $stkbot & 0xFF;
$bytes[ 0x401D - 0x4009 ] = ( $stkbot >> 8 ) & 0xFF;

# make E_PPC the first line number in the program
my $d_file = $bytes[ 0x400C - 0x4009 ] | ( $bytes[ 0x400D - 0x4009 ] << 8 );
if ( $d_file == 0x407D ) {

    # no lines in the program, make E_PPC = 0
    $bytes[ 0x400A - 0x4009 ] = 0;
    $bytes[ 0x400B - 0x4009 ] = 0;
}
else {
    my $line_num =
      ( $bytes[ 0x407D - 0x4009 ] << 8 ) | $bytes[ 0x407E - 0x4009 ];
    $bytes[ 0x400A - 0x4009 ] = $line_num & 0xFF;
    $bytes[ 0x400B - 0x4009 ] = ( $line_num >> 8 ) & 0xFF;
}

# patch NXTLIN
if ($AUTOSTART) {
    my $addr   = 0x407D;
    my $nxtlin = $d_file;
    while ( $addr < $d_file ) {
        my $line_num =
          ( $bytes[ $addr - 0x4009 ] << 8 ) | $bytes[ $addr + 1 - 0x4009 ];
        if ( $line_num >= $AUTOSTART_LINE ) {
            $nxtlin = $addr;
            last;
        }
        my $line_len =
          $bytes[ $addr + 2 - 0x4009 ] | ( $bytes[ $addr + 3 - 0x4009 ] << 8 );
        $addr += 4 + $line_len;
    }
    $bytes[ 0x4029 - 0x4009 ] = $nxtlin & 0xFF;
    $bytes[ 0x402A - 0x4009 ] = ( $nxtlin >> 8 ) & 0xFF;
}
else {
    $bytes[ 0x4029 - 0x4009 ] = $d_file & 0xFF;
    $bytes[ 0x402A - 0x4009 ] = ( $d_file >> 8 ) & 0xFF;
}

# write the file
path($p_file)->spew_raw( join '', map { chr } @bytes );
