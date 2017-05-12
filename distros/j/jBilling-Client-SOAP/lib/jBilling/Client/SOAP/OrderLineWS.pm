package jBilling::Client::SOAP::OrderLineWS;
    use 5.010;
    our $VERSION = 0.01;
      use Moose;
      extends 'jBilling::Client::SOAP::Object';
      has 'amount', is => 'rw', isa => 'Str';
      has 'createDatetime', is => 'rw', isa => 'Str';
      has 'deleted', is => 'rw', isa => 'Bool';
      has 'description', is => 'rw', isa => 'Str';
      has 'editable', is => 'rw', isa => 'Str';
      has 'id', is => 'rw', isa=> 'Str';
      has 'itemId', is => 'rw', isa=> 'Int';
      has 'orderId', is => 'rw', isa=> 'Int';
      has 'price', is => 'rw', isa=> 'Str';
      has 'priceStr', is => 'rw', isa=> 'Str';
      has 'provisioningRequestId', is => 'rw', isa=> 'Str';
      has 'provisioningStatusId', is => 'rw', isa=> 'Int';
      has 'quantity', is => 'rw', isa => 'Str';
      has 'typeId', is => 'rw', isa => 'Str';
      has 'useItem', is => 'rw', isa => 'Str';
      has 'orderLinePlanItems', is => 'rw', isa => 'Str';
      has 'versionNum', is => 'rw', isa => 'Int';
      has 'jbilling',          is => 'rw',   isa => 'jBilling::Client::SOAP';
      
      sub soapify{
        my $self = shift;
        my @ols;
        my @ol;
            foreach my $method ($self->getClassMethods){
                push @ol, SOAP::Data->new(name => $method, value => $self->$method)
                    if (defined $self->$method );
            }
            push @ols, \SOAP::Data->value(@ol);
        return @ols if @ols;
      }
1;