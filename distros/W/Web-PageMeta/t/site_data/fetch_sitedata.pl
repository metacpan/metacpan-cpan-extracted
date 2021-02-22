#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use Data::Dumper;
use Future::HTTP;
use URI::Escape qw(uri_escape);
use Path::Class qw(file dir);
use FindBin qw($Bin);

my $url = $ARGV[0] || die 'provide url as an argument';

Future::HTTP->new->http_get($url)->then(
    sub {
        my ( $body, $headers ) = @_;
        my $outfile_body = file( $Bin, uri_escape($url) );
        my $outfile_hdrs = file( $Bin, uri_escape($url).'.hdrs' );
        $outfile_body->spew( iomode => '>:raw', $body );
        $outfile_hdrs->spew( iomode => '>:raw', Dumper( $headers ) );
        say sprintf( '%s → %s', $url, $outfile_body );
    }
)->get;
