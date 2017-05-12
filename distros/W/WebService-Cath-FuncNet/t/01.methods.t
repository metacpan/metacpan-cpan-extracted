use Test::More tests => 2;
use strict;
use warnings;

use FindBin;
use URI::file;

BEGIN {
use_ok( 'WebService::Cath::FuncNet' );
}

my ( $ws, $wsdl, $wsdl_uri );

$wsdl = $FindBin::Bin . '/' . 'GecoService.wsdl';

$wsdl_uri = URI::file->new( $wsdl );

isa_ok( $ws = WebService::Cath::FuncNet->new( wsdl => $wsdl_uri ), 'WebService::Cath::FuncNet', 'new (local WSDL)' );
