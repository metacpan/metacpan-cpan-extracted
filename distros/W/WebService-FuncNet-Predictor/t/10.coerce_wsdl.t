use Test::More tests => 3;

use strict;
use warnings;
use FindBin;

use_ok( 'WebService::FuncNet::Predictor' );

my $obj = WebService::FuncNet::Predictor->new(
                wsdl => 'file:///' . $FindBin::Bin . '/GecoService.wsdl',
                port => 'GecoPort',
                service => 'GecoService',
                binding => 'GecoBinding',
          );

isa_ok( $obj, 'WebService::FuncNet::Predictor', 'new predictor object isa ok' );

isa_ok( $obj->wsdl, 'XML::Compile::WSDL11', 'wsdl object isa ok' );


