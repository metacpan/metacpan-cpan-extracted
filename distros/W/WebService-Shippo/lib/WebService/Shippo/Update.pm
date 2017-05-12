use strict;
use warnings;
use MRO::Compat 'c3';

package WebService::Shippo::Update;
require WebService::Shippo::Request;
use Params::Callbacks ( 'callbacks' );

sub update
{
    my ( $callbacks, $invocant, $id, @params ) = &callbacks;
    my $class = $invocant->item_class;
    my $response = Shippo::Request->put( $class->url( $id ), @params );
    return $class->construct_from( $response, $callbacks );
}

BEGIN {
    no warnings 'once';
    *Shippo::Updater:: = *WebService::Shippo::Updater::;
}

1;
