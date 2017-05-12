#
#===============================================================================
#         FILE:  Address.pm
#  DESCRIPTION:  Address Object for use with UPS
#       AUTHOR:  Kyle Brandt (mn), kyle@kbrandt.com , http://www.kbrandt.com
#===============================================================================


package WebService::UPS::Address;
use Mouse;

has '_address_hash' => ( is => 'rw' );

sub getCity {
    my $self = shift;
	return $self->_address_hash()->{City} // '';
}

sub getState {
    my $self = shift;
	return $self->_address_hash()->{StateProvinceCode} // '';
}

sub getZip {
    my $self = shift;
	return $self->_address_hash()->{PostalCode} // '';
}

sub getAddressLine1 {
    my $self = shift;
	return $self->_address_hash()->{AddressLine1} // '';
}


sub getAddressLine2 {
    my $self = shift;
	return $self->_address_hash()->{AddressLine2} // '';
}
1;

=head1 NAME

WebService::UPS::Address - Object to Represent Addresses 

=head1 SYNOPSIS

    my $Package = WebService::UPS::TrackRequest->new;
    $Package->Username('kbrandt');
    $Package->Password('topsecrent');
    $Package->License('8C3D7EE8FZZZZZ4');
    $Package->TrackingNumber('1ZA45Y5111111111');
    print $Package->Username();
    my $trackedpackage = $Package->requestTrack();
    my $address = $trackedpackage->getShipperAddress();
	print $address->getZip();
	

=head1 Methods

=head2 new()

    WebService::UPS::Address->new( _address_hash => $object->getShipperAddress());

The constructor method that creates a new address Object.  You probably should not be calling this directly as above, rather it should returned from the WebService::UPS::TrackedPackage Object

=over 1

=item _address_hash
    
You shouldn't be messing with it in general.  But if you dump it with dumper, and you are clever, you might be able to access things that my module doesn't have getters for.

=back

=head2 getCity()

    $address->getCity()

This and the following objects return strings.

=head2 getState()

    $address->getState()

=head2 getZip()

    $address->getCity()

=head2 getAddressLine1()

    $address->getAddressLine1()

=head2 getAddressLine2()

    $address->getAddressLine2()

=head1 AUTHOR

Kyle Brandt, kyle@kbrandt.com 
http://www.kbrandt.com

=cut
