#!/usr/bin/perl -w

use strict;
use utf8;
use Encode qw(encode decode);

#Test::More::diag ( "This backend is ", Text::CSV::Encoded->backend );

my $csv = Text::CSV::Encoded->new({});


for my $enc_in ( undef, qw(latin1 utf8) ) {
    for my $enc_out ( undef, qw(latin1 utf8) ) {

        $csv->encoding_in ( $enc_in  );
        $csv->encoding_out( $enc_out );

        ok( $csv->parse( $enc_in ? encode( $enc_in, "ü" ) : "ü" ) );
        is( ($csv->fields)[0], "ü" ); # always Unicode
        ok( $csv->combine( $csv->fields ) );
        is( $csv->string, $enc_out ? encode( $enc_out, "ü" ) : "ü" );

    }
}


for my $enc_in ( undef, qw(shiftjis utf8) ) {
    for my $enc_out ( undef, qw(shiftjis utf8) ) {

        $csv->encoding_in ( $enc_in  );
        $csv->encoding_out( $enc_out );

        my $subject  = $enc_in  ? $enc_in  : 'Unicode';
           $subject .= " => ";
           $subject .= $enc_out ? $enc_out : 'Unicode';
        ok(1,  $subject);

        ok( $csv->parse( $enc_in ? encode( $enc_in, "あ" ) : "あ" ) );
        is( ($csv->fields)[0], 'あ' ); # always Unicode
        ok( $csv->combine( $csv->fields ) );
        is( $csv->string, $enc_out ? encode( $enc_out, '"あ"' ) : '"あ"' );

    }
}


1;
