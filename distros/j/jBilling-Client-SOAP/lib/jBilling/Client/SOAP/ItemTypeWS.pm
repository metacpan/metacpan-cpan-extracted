package jBilling::Client::SOAP::ItemTypeWS;
    use 5.010;
    use Moose;
    extends 'jBilling::Client::SOAP::Object';
    
    has 'description',           is => 'rw', isa => 'Str';
    has 'id',                    is => 'rw', isa => 'Int';
    has 'orderLineTypeId',       is => 'rw', isa => 'Int';
    has 'hasDecimals',           is => 'rw', isa => 'Int';

1;