package jBilling::Client::SOAP::ItemDTOEx;
    use 5.010;
    use Moose;
    extends 'jBilling::Client::SOAP::Object';
    has 'currencyId',           is => 'rw', isa => 'Str';
    has 'deleted',              is => 'rw', isa => 'Int';
    has 'entityId',             is => 'rw', isa => 'Int';
    has 'hasDecimals',          is => 'rw', isa => 'Int';
    has 'id',                   is => 'rw', isa => 'Int';
    has 'orderLineTypeId',      is => 'rw', isa => 'Str';
    has 'types',                is => 'rw', isa => 'Int';
    has 'description',          is => 'rw', isa => 'Str';
    has 'glCode',               is => 'rw', isa => 'Str';
    has 'number',               is => 'rw', isa => 'Str';
    has 'percentage',           is => 'rw', isa => 'Str';
    has 'price',                is => 'rw', isa => 'Str';
    has 'promoCode',            is => 'rw', isa => 'Str';
    has 'metaFields',           is => 'bare', isa => 'arrayRef';
    has 'excludedTypes',        is => 'rw', isa => 'Int';
    has 'defaultPrice',         is => 'bare', isa => 'arrayRef';
    
    
    sub defaultPrice {
        my $self = shift;
        my @lines;
        my $item = shift;
        if ( ref($item) eq 'HASH' ) {
            my %hash = %{$item};
            my $line = jBilling::Client::SOAP::PriceModelWS->new();
            $line->load($item);
            push @lines, $line;
            $self->{defaultPrice} = \@lines;
        }
        elsif ( ref($item) eq 'ARRAY' ) {
            foreach my $v ( @{$item} ) {
                if ( ref($v) eq 'jBilling::Client::SOAP::PriceModelWS' ) {

                    # This is an object created by our Client
                    push @lines, $v;
                }
                elsif ( ref($v) eq 'HASH' ) {

                    #This is coming back from jBilling
                    my %hash = %{$v};
                    my $line = jBilling::Client::SOAP::PriceModelWS->new();
                    $line->load( \%hash );
                    push @lines, $line;
                }

            }
            $self->{defaultPrice} = \@lines;
        }
        else {
            return $self->{defaultPrice};
        }

    }
1;