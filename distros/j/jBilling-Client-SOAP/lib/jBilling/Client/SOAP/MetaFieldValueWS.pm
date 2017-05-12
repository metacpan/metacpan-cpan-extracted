package jBilling::Client::SOAP::MetaFieldValueWS;
    use 5.010;
    use Moose;
    our $VERSION = 0.02;
    extends 'jBilling::Client::SOAP::Object';
      has 'id',           is => 'rw', isa => 'Str';
      has 'fieldName',    is => 'rw', isa => 'Str';
      has 'stringValue',  is => 'rw', isa => 'Str';
      has 'displayOrder', is => 'rw', isa => 'Str';
      has 'dataType',     is => 'rw', isa => 'Str';
      has 'mandatory',    is => 'rw', isa => 'Str';
      has 'disabled',     is => 'rw', isa => 'Str';
  
    sub soapify{
        my $self = shift;
        my @ols;
        my @ol;
            foreach my $method ($self->getClassMethods){
                push @ol, SOAP::Data->new(name => $method, value => $self->$method)
                    if (defined $self->$method );
            }
            push @ols, \SOAP::Data->value(@ol);
        return SOAP::Data->name("metaFields" => @ols)
                         ->type("metaFields") if @ols;
      }
  
  

1;
