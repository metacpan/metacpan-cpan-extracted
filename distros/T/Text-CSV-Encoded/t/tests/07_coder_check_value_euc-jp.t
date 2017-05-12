#!/usr/bin/perl -w

# This file is encoded in EUC-JP, and output is Shift_JIS.
# このファイルのエンコーディングはEUC-JP、出力はShift_JIS。

use strict;

BEGIN {
    local $ENV{PERL_TEXT_CSV} = $ARGV[0] || 0;
    require Text::CSV::Encoded;
}


use Encode;

my $str   = 'あ,い,〜,��';
my $check = encode( 'shiftjis', decode( 'euc-jp', '"あ","い","〜",' ) );

my @cols;
my $csv = Text::CSV::Encoded->new( { encoding_in => 'euc-jp', encoding_out => 'shiftjis' } );

$csv->parse( $str );
@cols = $csv->fields;
$csv->combine( @cols );
is( $csv->string, $check . '"?"' );

# change check value
$csv->coder->encode_check_value( Encode::FB_PERLQQ );

$csv->parse( $str );
@cols = $csv->fields;
$csv->combine( @cols );
is( $csv->string, $check . '"\x{2460}"' );

1;
