#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use File::Temp qw/tempfile/;

use Test::MockFile qw<nostrict>;    # Everything below this can have its open overridden.

note "-------------- REAL MODE --------------";
my ( $fh_real, $filename ) = tempfile();
print $fh_real "will be thrown out";
close $fh_real;
is( -s $filename, 18, "tempfile originally writes out 16 bytes" );

is( open( $fh_real, ">", $filename ), 1, "Open file for overwrite" );
like( "$fh_real", qr/^GLOB\(0x[0-9a-f]+\)$/, '$real_fh stringifies to a GLOB' );
print {$fh_real} "not\nmocked\n";
is( close $fh_real, 1, "Close \$real_fh" );
ok( $!, '$! hasn\'t been cleared' );
is( -s $filename, 11, "Temp file is on disk and right size assuming a re-write happened." );

note "-------------- MOCK MODE --------------";
my $bar = Test::MockFile->file($filename);
is( open( my $fh, '>', $filename ), 1, "Mocked temp file opens for write and returns true" );
isa_ok( $fh, ["IO::File"], '$fh is a IO::File' );
like( "$fh", qr/^IO::File=GLOB\(0x[0-9a-f]+\)$/, '$fh stringifies to a IO::File GLOB' );
my $oneline = "Just one line";
is( ( print {$fh} $oneline ), 1,        "overwrite the contents" );
is( $bar->contents,           $oneline, '$foo->contents reflects an overwrite' );
is( close($fh),               1,        'Close $fh' );
ok( $!, '$! hasn\'t been cleared' );

is( open( $fh, '>>', $filename ),       1,  'Re-open $fh for append' );
is( ( print $fh " but really long\n" ), 1,  "Append line" );
my $bytes = printf $fh "%04d", 42;
is( $bytes,         1,                                "printf returns 1 (success)" );
is( $bar->contents, "$oneline but really long\n0042", '$foo->contents reflects an append' );
my $undef_len = print $fh undef;
is( $undef_len, 1, "Printing undef returns 1 (success) and is not a warning." );
my $empty_ret = print $fh "";
is( $empty_ret, 1, "Printing empty string returns 1 (success), not 0" );
ok( ( print $fh "" or 1 ), "print empty string is truthy (print or die pattern works)" );
is( close($fh), 1, 'Close $fh' );
ok( $!, '$! hasn\'t been cleared' );
undef $bar;

note "-------------- REAL MODE --------------";
is( -s $filename, 11, "Temp file on disk is unaltered once \$bar is clear." );

done_testing();
