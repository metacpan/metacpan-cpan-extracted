#
#===============================================================================
#         FILE:  Activity.pm
#  DESCRIPTION:  Activity Object for my OO UPS Tracking Module
#       AUTHOR:  Kyle Brandt (mn), kyle@kbrandt.com , http://www.kbrandt.com
#===============================================================================

use strict;
use warnings;

package WebService::UPS::Activity;
use Mouse;

has '_activity_hash' => ( is => 'rw' );

sub getTime {
    my $self = shift;
    return $self->_activity_hash()->{Time} // '';
}

sub getAddress {
	my $self = shift;
	my $addressObject = WebService::UPS::Address->new( _address_hash => $self->_activity_hash()->{ActivityLocation}{Address}) // '';
	return $addressObject;
}

sub getDescription {
	my $self = shift;
	my $description = $self->_activity_hash()->{Status}{StatusType}{Description} // '';
	return $description;
}

sub getDate {
	my $self = shift;
	return $self->_activity_hash()->{Date} // '';
}
1;

=head1 NAME

WebService::UPS::Activity - Object to Represent a particular tracked event in the package's adventure

=head1 SYNOPSIS

    my $Package = WebService::UPS::TrackRequest->new;
    $Package->Username('kbrandt');
    $Package->Password('topsecrent');
    $Package->License('8C3D7EE8FZZZZZ4');
    $Package->TrackingNumber('1ZA45Y5111111111');
    print $Package->Username();
    my $trackedpackage = $Package->requestTrack();
    my $activity = $trackedpackage->getActivity(0);
    print $activity->getTime();
    

=head1 Methods

=head2 new()

    WebService::UPS::Activity->new( _activity_hash => $object->getActiviy(0));

The constructor method that creates a new Activity object.  You probably should not be calling this directly as above, rather it should returned from the WebService::UPS::TrackedPackage Object

=over 1

=item _activity_hash
    
You shouldn't be messing with it in general.  But if you dump it with dumper, and you are clever, you might be able to access things that my module doesn't have getters for.

=back

=head2 getTime()

    $activity->getTime()

Returns the time as a string, I will leave it up to you to make it into a datetime object.

=head2 getAddress()

    $activity->getAddress()

Returns an address object which represents the location of the activity

=head2 getDescription()

	$activity->getDescription()

returns a string that describes the action for this activity entry, for example 'OUT FOR DELIVERY'

=head2 getDate()
	
	$activity->getDate()

Returns String, like 052297

=head1 AUTHOR

Kyle Brandt, kyle@kbrandt.com 
http://www.kbrandt.com

=cut


