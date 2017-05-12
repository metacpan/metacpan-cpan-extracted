package jBilling::Client::SOAP::PriceModelWS;
    use 5.010;
    our $VERSION = 0.01;
    use Moose;
    extends 'jBilling::Client::SOAP::Object';
    has 'id',                   is => 'rw', isa => 'Int';
    has 'type',                 is => 'rw', isa => 'Str';
    has 'rate',                 is => 'rw', isa => 'Str';
    has 'currencyId',           is => 'rw', isa => 'Int';

1;