#!/usr/bin/perl

use warnings;
use strict;
use Tie::Handle::HTTP;

tie( *FOO, 'Tie::Handle::HTTP', 'http://hachi.kuiki.net/stuff/mdns.perl' );
#Tie::Handle::HTTP->open( my $handle, "http://hachi.kuiki.net/stuff/mdns.perl" );

my $content;

while( 1 or !eof(FOO) ) {
    my $length = read( FOO, my $buf, 512 );

    if (!defined( $length )) {
        die( "Read failed: $!\n" );
    }

    last unless $length;

    $content .= $buf;
    warn "Read of $length bytes succeeded, got: $buf\n"
}

warn "Ended nicely!\n";
