package jBilling::Client::SOAP::Object;
    our $VERSION = 0.02;
    use 5.010;
      use Moose;
      use Scalar::Util qw(looks_like_number);
      
      sub load {
        my $self     = shift;
        my $response = shift;
        while ( ( my $key, my $value ) = each(%$response) ) {
            if ( defined $value and $value ne '' ) {
                if ( $self->can($key) ) {

                    #Set the value on the object
                    $self->$key($value);
                }
            }
        }
    }

    sub getClassMethods {
        my $self      = shift;
        my $meta      = Moose::Meta::Class->initialize( ref($self) );
        my $classname = ref($self);
        my @methods;
        for my $meth ( $meta->get_all_methods ) {
            push( @methods, $meth->name )
              if (  $meth->fully_qualified_name =~ m/$classname/
                and $meth->name !~ m/BUILD|soapify|meta$|jbilling/ );
        }
        return @methods;
    }

    sub save {
        my $self = shift;

        if ( !defined $self->jbilling ) {
            throw jBilling::Client::SOAP::Exception 'No jBilling Connection';
        }
        else {
            if ( ref($self) =~ m/OrderWS$/ ) {

                #this is an Order object
                if ( defined $self->id ) {

                    # We have an order id so order has been loaded
                    $self->jbilling->createUpdateOrder(
                        SOAP::Data->value( $self->soapify ) );

                    # Update the defined order
                }
                elsif ( !defined $self->id ) {

                    # No Order ID so create a new one
                    my $response = $self->jbilling->createOrder(
                        SOAP::Data->value( $self->soapify ) );
                    return $response;
                } 
            }
            if ( ref($self) =~ m/OrderLineWS$/) {
                # This is called to update an Individual OrderLine
                # API does not return anything so
                $self->jbilling->updateOrderLine(
                        $self->soapify
                );
            }
            
        }
    }

    sub retrieve {
        my $self = shift;
        if ( !defined $self->jbilling ) {
            throw jBilling::Client::SOAP::Exception 'No jBilling Connection';
        }
        else {
            if ( ref($self) =~ m/OrderWS$/ ) {

                #this is an Order object
                if ( !defined $self->id ) {
                    throw jBilling::Client::SOAP::Exception
                      'No ID so cannot retrieve';
                }
                else {
                    $self->jbilling->getOrder( $self->id );
                    return $self;
                }

            }
        }
    }

    sub metaFields {
        my $self = shift;
        my @lines;
        my $item = shift;
        if ( ref($item) eq 'HASH' ) {
            my %hash = %{$item};
            my $line = jBilling::Client::SOAP::MetaFieldValueWS->new();
            $line->load($item);
            push @lines, $line;
            $self->{metaFields} = \@lines;
        }
        elsif ( ref($item) eq 'ARRAY' ) {
            foreach my $v ( @{$item} ) {
                if ( ref($v) eq 'jBilling::Client::SOAP::MetaFieldValueWS' ) {

                    # This is an object created by our Client
                    push @lines, $v;
                }
                elsif ( ref($v) eq 'HASH' ) {

                    #This is coming back from jBilling
                    my %hash = %{$v};
                    my $line = jBilling::Client::SOAP::MetaFieldValueWS->new();
                    $line->load( \%hash );
                    push @lines, $line;
                }

            }
            $self->{metaFields} = \@lines;
        }
        else {
            return $self->{metaFields};
        }

    }
    

        

1;

=pod

=encoding UTF-8

=head1 NAME

jBilling::Client::SOAP::Object

=head1 VERSION

version 0.01

=head1 AUTHOR

Aaron Guise <guisea@cpan.org>

=head1 Functions

=head2 load

The load method is tasked with taking values returned by jBilling and
loading them into fields within the perl object.

=head2 retrieve

The retrieve method ensures an active connection is available to jBilling
and calls methods that return data via the API.

=head2 save

The save method is called to save our Objects to jBilling.  Will soapify
the object and transport it.

=head2 metaFields

The metaFields method either returns metafields 

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Aaron Guise.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
