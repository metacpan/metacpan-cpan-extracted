use strict;
use warnings;
use MRO::Compat 'c3';

package WebService::Shippo::Create;
require WebService::Shippo::Request;
use Params::Callbacks ( 'callbacks' );

sub create
{
    my ( $callbacks, $invocant, @params ) = &callbacks;
    my $class = $invocant->item_class;
    my $response = Shippo::Request->post( $class->url, @params );
    return $class->construct_from( $response, $callbacks );
}

BEGIN {
    no warnings 'once';
    *Shippo::Creator:: = *WebService::Shippo::Creator::;
}

1;
