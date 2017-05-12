#!/usr/bin/perl
# vim: filetype=perl

use warnings;
use strict;
use Test::More;

ok( tell( FOO ) == 0, "Start at 0" );
ok( !eof( FOO), "Not at end of file, good" );
readmatch( "Lorem ipsum dolor sit amet" );
ok( !eof( FOO), "Not at end of file, good" );
readmatch( ", consectetuer adipiscing elit" );
ok( seek( FOO, 0, 0 ), "Seek success" );
ok( tell( FOO ) == 0, "Seek to 0" );
readmatch( "Lorem ipsum dolor sit amet" );
ok( !eof( FOO), "Not at end of file, good" );
readmatch( ", consectetuer adipiscing elit" );
ok( !eof( FOO), "Not at end of file, good" );
readmatch( ", sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat." );
ok( !eof( FOO), "Not at end of file, good" );

my $string = "Eodem modo typi, qui nunc nobis videntur parum clari, fiant sollemnes in futurum.\n";
ok( seek( FOO, 0-length( $string ), 2 ), "Seek success" );
readmatch( $string );
ok( eof( FOO ), "At end of file when we should be" );

sub readmatch {
    my $string = shift;
    my $length = length( $string );

    my $pos = tell( FOO );

    {
        diag( "Requesting $length bytes: '$string'" ) if VERBOSE;

        my $bytes = read( FOO, my $content, $length );

        diag( "Got $bytes bytes: '$content'" ) if VERBOSE;

        ok( $bytes, "Read success" );
        ok( $bytes == $length, "Read of $length succeeded" );
        ok( $content eq $string, "Read of string succeeded" );
    }

    ok( seek( FOO, 0-$length, 1 ), "Seek success" );

    ok( tell( FOO ) == $pos, "seek took us back where we started: $pos" );
    
    {
        diag( "Requesting $length bytes: '$string'" ) if VERBOSE;

        my $bytes = read( FOO, my $content, $length );

        diag( "Got $bytes bytes: '$content'" ) if VERBOSE;

        ok( $bytes, "Read success" );
        ok( $bytes == $length, "Read of $length succeeded" );
        ok( $content eq $string, "Read of string succeeded" );
    }
}

1;
