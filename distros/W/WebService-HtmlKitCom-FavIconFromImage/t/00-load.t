#!perl

use strict;
use warnings;

use Test::More tests => 11;

BEGIN {
    use_ok('Carp');
    use_ok('WWW::Mechanize');
    use_ok('Devel::TakeHashArgs');
    use_ok('Class::Accessor::Grouped');
    use_ok( 'WebService::HtmlKitCom::FavIconFromImage' );
}

diag( "Testing WebService::HtmlKitCom::FavIconFromImage $WebService::HtmlKitCom::FavIconFromImage::VERSION, Perl $], $^X" );

my $o = WebService::HtmlKitCom::FavIconFromImage->new(timeout=>30);
isa_ok($o,'WebService::HtmlKitCom::FavIconFromImage');
isa_ok($o->mech, 'WWW::Mechanize');
can_ok($o,qw(new favicon error response _set_error mech));
SKIP:{
    my $response = $o->favicon('t/pic.jpg');
    unless ( $response ) {
        diag "\nGOT ERROR: " . $o->error . "\n\n";
        skip 'Got error', 3;
    }
    isa_ok( $response, 'HTTP::Response', 'isa of return value of favicon()');
    is( $response->header('Content-type'), 'application/zip',
        'should get zip file from favicon()'
    );
    is_deeply( $response, $o->response, 'response() method');
}

