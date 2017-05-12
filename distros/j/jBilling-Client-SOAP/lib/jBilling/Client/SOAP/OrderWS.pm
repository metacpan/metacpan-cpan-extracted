package jBilling::Client::SOAP::OrderWS;
    use 5.010;
    our $VERSION = 0.05;
      use Moose;

      extends 'jBilling::Client::SOAP::Object';

      has 'activeSince',       is => 'rw',   isa => 'Str';
      has 'activeUntil',       is => 'rw',   isa => 'Str';
      has 'anticipatePeriods', is => 'rw',   isa => 'Str';
      has 'billingTypeId',     is => 'rw',   isa => 'Int';
      has 'billingTypeStr',    is => 'rw',   isa => 'Str';
      has 'createDate',        is => 'rw',   isa => 'Str';
      has 'createdBy',         is => 'rw',   isa => 'Int';
      has 'currencyId',        is => 'rw',   isa => 'Int';
      has 'deleted',           is => 'rw',   isa => 'Bool';
      has 'dtFM',              is => 'rw',   isa => 'Int';
      has 'dueDateUnitId',     is => 'rw',   isa => 'Int';
      has 'dueDateValue',      is => 'rw',   isa => 'Str';
      has 'generatedInvoices', is => 'rw',   isa => 'Str';
      has 'id',                is => 'rw',   isa => 'Int';
      has 'lastNotified',      is => 'rw',   isa => 'Str';
      has 'nextBillableDay',   is => 'rw',   isa => 'Str';
      has 'notes',             is => 'rw',   isa => 'Str';
      has 'notesInInvoice',    is => 'rw',   isa => 'Str';
      has 'notificationStep',  is => 'rw',   isa => 'Str';
      has 'notify',            is => 'rw',   isa => 'Str';
      has 'orderLines',        is => 'bare', isa => 'arrayRef';
      has 'ownInvoice',        is => 'rw',   isa => 'Int';
      has 'period',            is => 'rw',   isa => 'Int';
      has 'periodStr',         is => 'rw',   isa => 'Str';
      has 'pricingFields',     is => 'rw',   isa => 'Str';
      has 'statusId',          is => 'rw',   isa => 'Int';
      has 'statusStr',         is => 'rw',   isa => 'Str';
      has 'timeUnitStr',       is => 'rw',   isa => 'Str';
      has 'total',             is => 'rw',   isa => 'Str';
      has 'userId',            is => 'rw',   isa => 'Int';
      has 'metaFields',        is => 'bare', isa => 'arrayRef';
      has 'versionNum',        is => 'rw',   isa => 'Int';
      has 'isCurrent',         is => 'rw',   isa => 'Str';
      has 'cycleStarts',       is => 'rw',   isa => 'Str';
      has 'jbilling',          is => 'rw',   isa => 'jBilling::Client::SOAP';

    sub orderLines {
        my $self = shift;
        my @lines;
        my $item = shift;
        if ( ref($item) eq 'HASH' ) {

            #code
            my %hash = %{$item};
            my $line = jBilling::Client::SOAP::OrderLineWS->new();
            $line->load($item);
            push @lines, $line;
            $self->{orderLines} = \@lines;
        }
        elsif ( ref($item) eq 'ARRAY' ) {
            foreach my $v ( @{$item} ) {
                if (ref($v) eq 'jBilling::Client::SOAP::OrderLineWS'){
                   # This is an object created by our Client
                   push @lines, $v;
                } elsif (ref($v) eq 'HASH') {
                    #This is coming back from getOrder
                    my %hash = %{$v};
                    my $line = jBilling::Client::SOAP::OrderLineWS->new();
                    $line->load(\%hash);
                    push @lines, $line;
                }
                
            }
            $self->{orderLines} = \@lines;
        }
        else {
            return $self->{orderLines};
        }

    }
    
   sub soapify {
        my $self = shift;
        my @soap; # This Array will store our SOAP::Data Object
        my @ols; # Stores array of OrderLines
        my @mfs; # Stores array of Metafields
        
        # Collect our class metadata
        foreach my $method ($self->getClassMethods){
            push @soap, SOAP::Data->new(name => $method, value => $self->$method)
                    if (defined $self->$method
                        and $method ne 'orderLines'
                        and $method ne 'metaFields'
                        );
        }
        
        # Populate any OrderLines contained in the object.
        if (defined $self->orderLines ) {
            foreach my $ol (@{$self->orderLines}){
            push @ols, SOAP::Data->name("orderLines" => $ol->soapify)->type("orderLines");
            }
        }
        

         # Populate any MetaFields contained in the object.
        if (defined $self->metaFields) {
            foreach my $mf (@{$self->metaFields}){
            push @mfs, $mf->soapify;
        }
        }
        
        push @soap, @ols if @ols;
                         
        push @soap, @mfs if @mfs; # Push MetaFields if they are present
        my $soapreq = SOAP::Data->name("arg0" => \@soap); # This combines our SOAP::Data array into the arg0 Parameter expected by jbilling's API
        return $soapreq

    }

  1;
