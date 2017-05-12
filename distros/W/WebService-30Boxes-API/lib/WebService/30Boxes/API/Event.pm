package WebService::30Boxes::API::Event;

use strict;
use warnings;
use Carp qw/croak/;

our $VERSION = '1.05';

sub new {
	my ($class, $result, $success, $error_code, $error_message) = @_;
	croak "The response from 30Boxes was not a success" unless $result->{'success'};

	#%{$result->{'_xml'}->{'eventList'} is a hash with listEnd, listStart, userId, event as keys
	#%{$result->{'_xml'}->{'eventList'}->{'event'}} is a hash with event ids as keys
	my $self = {	listEnd => $result->{'_xml'}->{'eventList'}->{'listEnd'},
			listStart => $result->{'_xml'}->{'eventList'}->{'listStart'},
			userId => $result->{'_xml'}->{'eventList'}->{'userId'},
			event => $result->{'_xml'}->{'eventList'}->{'event'},
			eventIds => [sort keys %{$result->{'_xml'}->{'eventList'}->{'event'}}],
			eventIndex => -1,
			success => $success,
			error_code => $error_code,
			error_message => $error_message,
	};
	bless $self, $class;
	return $self;
}

#return an array of event ids
sub get_eventIds {
	my ($self) = @_;
	return @{$self->{'eventIds'}};
}

#return a reference to an array of event ids
sub get_ref_eventIds {
	my ($self) = @_;
	return $self->{'eventIds'};
}

#get the end date of the list - yyyy-mm-dd
sub get_listEnd {
	my ($self) = @_;
	return $self->{'listEnd'};
}
	
#get the start date of the list - yyyy-mm-dd
sub get_listStart {
	my ($self) = @_;
	return $self->{'listStart'};
}
	
#get the current user id
sub get_userId {
	my ($self) = @_;
	return $self->{'userId'};
}

#advance the eventIndex
sub nextEventId {
	my ($self) = @_;
	return 0 if $self->{'eventIndex'} == scalar(@{$self->{'eventIds'}}) - 1;
	return $self->{'eventIds'}->[$self->{'eventIndex'}++];
}
	
#get the date when the recurring event stops repeating - yyyy-mm-dd
#0000-00-00 if none
#if an event spans over multiple days but it is not recurring, the final date will be returned
sub get_repeatEndDate {
	my ($self, $eventId) = @_;
	$eventId = $self->{'eventIds'}->[$self->{'eventIndex'}] if 0 == $#_;
	return $self->{'event'}->{$eventId}->{'repeatEndDate'};
}

#return a list of the days that are skipped
sub get_repeatSkipDates {
	my ($self, $eventId) = @_;
	$eventId = $self->{'eventIds'}->[$self->{'eventIndex'}] if 0 == $#_;
	my $temp = $self->{'event'}->{$eventId}->{'repeatSkipDates'};
	if (ref $temp){return qw//;}
	$temp =~ s/\s+/ /;
	return split(/ /, $temp);
}

#return the repeat type for the event
#returns 'no' if none
sub get_repeatType {
	my ($self, $eventId) = @_;
	$eventId = $self->{'eventIds'}->[$self->{'eventIndex'}] if 0 == $#_;
	return $self->{'event'}->{$eventId}->{'repeatType'};
}

#return the repeat interval for the event
#this together with get_repeatType tell you all you need to know about how the event repeats
sub get_repeatInterval {
	my ($self, $eventId) = @_;
	$eventId = $self->{'eventIds'}->[$self->{'eventIndex'}] if 0 == $#_;
	$self->{'event'}->{$eventId}->{'repeatICal'} =~ /INTERVAL=(\d+)/;
	my $interval = $1;
	return $interval;
}

#returns the number of minutes before the event when the reminder will be sent
#-1 if no reminder
sub get_reminder {
	my ($self, $eventId) = @_;
	$eventId = $self->{'eventIds'}->[$self->{'eventIndex'}] if 0 == $#_;
	return $self->{'event'}->{$eventId}->{'reminder'};
}

#returns a list of tags
sub get_tags {
	my ($self, $eventId) = @_;
	$eventId = $self->{'eventIds'}->[$self->{'eventIndex'}] if 0 == $#_;
	my $temp = $self->{'event'}->{$eventId}->{'tags'};
	return "" if ref($temp);
	$temp =~ s/\s+/ /;
	return split(/ /, $temp);
}

#gets the end date
sub get_endDate {
	my ($self, $eventId) = @_;
	$eventId = $self->{'eventIds'}->[$self->{'eventIndex'}] if 0 == $#_;
	my $temp = $self->{'event'}->{$eventId}->{'end'};
	return (split(/ /, $temp))[0];
}

#gets the end time - hh:mm:ss
sub get_endTime {
	my ($self, $eventId) = @_;
	$eventId = $self->{'eventIds'}->[$self->{'eventIndex'}] if 0 == $#_;
	my $temp = $self->{'event'}->{$eventId}->{'end'};
	return (split(/ /, $temp))[1];
}

#returns 1 if it is an all day event, 0 otherwise
sub isAllDayEvent {
	my ($self, $eventId) = @_;
	$eventId = $self->{'eventIds'}->[$self->{'eventIndex'}] if 0 == $#_;
	return $self->{'event'}->{$eventId}->{'allDayEvent'};
}

#gets the title for the event
sub get_title {
	my ($self, $eventId) = @_;
	$eventId = $self->{'eventIds'}->[$self->{'eventIndex'}] if 0 == $#_;
	return $self->{'event'}->{$eventId}->{'summary'};
}

#gets the notes for the event in the form of a string
#if the notes span over multiple lines, the order in which they are returned is undefined
sub get_notes {
	my ($self, $eventId) = @_;
	$eventId = $self->{'eventIds'}->[$self->{'eventIndex'}] if 0 == $#_;
	my $temp = $self->{'event'}->{$eventId}->{'notes'};
	if (not ref $temp){
		return $temp;
	}

	return "" if not defined $temp->{'content'};

	my $temp2 = $temp->{'content'};

	return join("\n", @{$temp2});
}


sub get_privacy {
	my ($self, $eventId) = @_;
	$eventId = $self->{'eventIds'}->[$self->{'eventIndex'}] if 0 == $#_;
	return $self->{'event'}->{$eventId}->{'privacy'};
}

#gets the start date - yyyy-mm-dd
sub get_startDate {
	my ($self, $eventId) = @_;
	$eventId = $self->{'eventIds'}->[$self->{'eventIndex'}] if 0 == $#_;
	my $temp = $self->{'event'}->{$eventId}->{'start'};
	return (split(/ /, $temp))[0];
}

#gets the start time - hh:mm:ss
sub get_startTime {
	my ($self, $eventId) = @_;
	$eventId = $self->{'eventIds'}->[$self->{'eventIndex'}] if 0 == $#_;
	my $temp = $self->{'event'}->{$eventId}->{'start'};
	return (split(/ /, $temp))[1];
}

sub get_externalUID {
	my ($self, $eventId) = @_;
	$eventId = $self->{'eventIds'}->[$self->{'eventIndex'}] if 0 == $#_;
	my $temp = $self->{'event'}->{$eventId}->{'externalUID'};
	return "" if ref($temp);#it's a hash if empty
	$temp =~ s/\s+/ /;
	return split(/ /, $temp);
}

1;
__END__

=head1 NAME

WebService::30Boxes::API::Event - Object returned by WebService::30Boxes::API::call("events.Get*

=head1 SYNOPSIS

  #$api_key and $auth_token are defined before
  my $boxes = WebService::30Boxes::API->new(api_key => $api_key);

  my $events = $boxes->call('events.Get', {authorizedUserToken => $auth_token});
  if($events->{'success'}){
  	print "List start: " . $events->get_listStart . "\n";
  	print "List end: " . $events->get_listEnd . "\n";
  	print "User Id: " . $events->get_userId . "\n\n\n";
  
  	#while ($events->nextEventId){ - if you use this, you don't need to specify
  	#$_ as an argument
  	#foreach (@{$events->get_ref_eventIds}){
  	foreach ($events->get_eventIds){
  		print "Event id: $_\n";
  		print "Title: " . $events->get_title($_) . "\n";
  		print "Repeat end date: " . $events->get_repeatEndDate($_) . "\n";
  		print "Repeat skip dates: ";
  		foreach ($events->get_repeatSkipDates($_)){print "$_\n";}
  		print "Repeat type: " . $events->get_repeatType($_) . "\n";
  		print "Repeat interval: " . $events->get_repeatInterval($_) . "\n";
  		print "Reminder: " . $events->get_reminder($_) . "\n";
  		print "Tags: ";
  		foreach ($events->get_tags($_)){print "$_\n";}
  		print "Start date: " . $events->get_startDate($_) . "\n";
  		print "Start time: " . $events->get_startTime($_) . "\n";
  		print "End date: " . $events->get_endDate($_) . "\n";
  		print "End time: " . $events->get_endTime($_) . "\n";
  		print "Is all day event: " . $events->isAllDayEvent($_) . "\n";
  		print "Notes: ";
  		foreach ($events->get_notes($_)){print "$_\n";}
  		print "Privacy: " . $events->get_privacy($_) . "\n\n";
  		print "External UID: " . $events->get_externalUID($_) . "\n\n";
  	}
  }
  else{
  	print "An error occured (" . $events->{'error_code'} . ": " .
  		$events->{'error_msg'} . ")\n";
  }

=head1 DESCRIPTION

An object of this type is returned by the WebService::30Boxes::API::call("events.Get*") function

=head2 METHODS

The following methods can be used

=head3 new

Create a new C<WebService::30Boxes::API::Event> object.

=over 5

=item result

(B<Mandatory>) Result must be the the hash function returned by the XML parser. 
Results are undefined if some other hash is passed in.

=item success

(B<Mandatory>) If the API call was successful or not.

=item error_code

(B<Optional>) If success is false, this must be supplied

=item error_message

(B<Optional>) If success is false, this must be supplied

=back

=head3 get_eventIds

Returns an array of event ids.

You can then use this to call any of the following functions.

=head3 get_ref_eventIds

Returns a reference to an array of event ids.

You can then use this to call any of the following functions.

=head3 get_listEnd

Returns the end date of the list of events - yyyy-mm-dd.

=head3 get_listStart

Returns the start date of the list of events - yyyy-mm-dd.

=head3 get_userId

Returns the current user id.

=head3 nextEventId

Advances the event index and returns the new eventID (for convenience)

=head3 get_repeatEndDate

Returns the date when the recurring event stops repeating - yyyy-mm-dd. 
Returns 0000-00-00 if none. 
If an event spans over multiple days but it is not recurring, the final date will be returned. 

Arguments:

=over 5

=item eventId

(B<Optional>) The eventId of the event for which you want to retreive the information. 
If not present, the next eventId will be used as an index. The next eventId is set by calling nextEventId.

=back

=head3 get_repeatSkipDates

Returns a list of the days that are skipped.

Arguments:

=over 5

=item eventId

(B<Optional>) The eventId of the event for which you want to retreive the information. 
If not present, the next eventId will be used as an index. The next eventId is set by calling nextEventId.

=back

=head3 get_repeatType

Returns the repeat type for the event. 
Returns 'no' if none.

Arguments:

=over 5

=item eventId

(B<Optional>) The eventId of the event for which you want to retreive the information. 
If not present, the next eventId will be used as an index. The next eventId is set by calling nextEventId.

=back

=head3 get_repeatInterval

Returns the repeat interval for the event. 
This together with get_repeatType tell you all you need to know about how the event repeats. 

Arguments:

=over 5

=item eventId

(B<Optional>) The eventId of the event for which you want to retreive the information.
If not present, the next eventId will be used as an index. The next eventId is set by calling nextEventId.

=back

=head3 get_reminder

Returns the number of minutes before the event when the reminder will be sent. 
Returns -1 if no reminder.

Arguments:

=over 5

=item eventId

(B<Optional>) The eventId of the event for which you want to retreive the information.
If not present, the next eventId will be used as an index. The next eventId is set by calling nextEventId.

=back

=head3 get_tags

Returns a list of tags.

Arguments:

=over 5

=item eventId

(B<Optional>) The eventId of the event for which you want to retreive the information. 
If not present, the next eventId will be used as an index. The next eventId is set by calling nextEventId.

=back

=head3 get_startDate

Returns the start date for the event - yyyy-mm-dd.

Arguments:

=over 5

=item eventId

(B<Optional>) The eventId of the event for which you want to retreive the information.
If not present, the next eventId will be used as an index. The next eventId is set by calling nextEventId.

=back

=head3 get_startTime

Returns the start time for the event - hh:mm:ss.

Arguments:

=over 5

=item eventId

(B<Optional>) The eventId of the event for which you want to retreive the information. 
If not present, the next eventId will be used as an index. The next eventId is set by calling nextEventId.

=back

=head3 get_endDate

Returns the end date for the event - yyyy-mm-dd.

Arguments:

=over 5

=item eventId

(B<Optional>) The eventId of the event for which you want to retreive the information. 
If not present, the next eventId will be used as an index. The next eventId is set by calling nextEventId.

=back

=head3 get_endTime

Returns the end time for the event - hh:mm:ss.

Arguments:

=over 5

=item eventId

(B<Optional>) The eventId of the event for which you want to retreive the information. 
If not present, the next eventId will be used as an index. The next eventId is set by calling nextEventId.

=back

=head3 isAllDayEvent

Returns 1 if it is an all day event, 0 otherwise.

Arguments:

=over 5

=item eventId

(B<Optional>) The eventId of the event for which you want to retreive the information. 
If not present, the next eventId will be used as an index. The next eventId is set by calling nextEventId.

=back

=head3 get_title

Returns the title for the event. 

Arguments:

=over 5

=item eventId

(B<Optional>) The eventId of the event for which you want to retreive the information. 
If not present, the next eventId will be used as an index. The next eventId is set by calling nextEventId.

=back

=head3 get_notes

Return the notes for the event in the form of a string. 
If the notes span over multiple lines, the order in which they are returned is undefined.

Arguments:

=over 5

=item eventId

(B<Optional>) The eventId of the event for which you want to retreive the information. 
If not present, the next eventId will be used as an index. The next eventId is set by calling nextEventId.

=back

=head3 get_privacy

Returns whether the event is shared or private. 
Return value is a string.

Arguments:

=over 5

=item eventId

(B<Optional>) The eventId of the event for which you want to retreive the information. 
If not present, the next eventId will be used as an index. The next eventId is set by calling nextEventId.

=back

=head3 get_externalUID

Returns the user defined ID for this event
The return value is a string

Arguments:

=over 5

=item eventId

(B<Optional>) The eventId of the event for which you want to retreive the information. 
If not present, the next eventId will be used as an index. The next eventId is set by calling nextEventId.

=back

=head1 TODO

Add more error checking. Compact the code and make it more efficient. Please email me for feature requests.

=head1 BUGS

Please notify chitoiup@umich.edu of any bugs.

=head1 SEE ALSO

L<http://30boxes.com/>, L<http://30boxes.com/api/>

L<WebService::30Boxes::API>

L<WebService::30Boxes::API::Todo>

=head1 AUTHOR

Robert Chitoiu, E<lt>chitoiup@umich.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Robert Chitoiu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
