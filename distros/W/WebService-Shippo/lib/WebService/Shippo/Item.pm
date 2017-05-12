use strict;
use warnings;
use MRO::Compat 'c3';

package WebService::Shippo::Item;
use base ( 'WebService::Shippo::Resource' );

BEGIN {
    no warnings 'once';
    *Shippo::Item:: = *WebService::Shippo::Item::;
}

1;
