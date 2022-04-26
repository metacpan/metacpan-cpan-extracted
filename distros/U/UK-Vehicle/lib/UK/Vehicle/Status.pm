package UK::Vehicle::Status;

use 5.030000;
use strict;
use warnings;
use subs qw(dateOfLastV5CIssued manufacturer markedForExport monthOfFirstRegistration motExpiryDate vrm taxDueDate yearOfManufacture wheelPlan);
use Class::Tiny qw(result message co2Emissions colour dateOfLastV5CIssued engineCapacity euroStatus fuelType make manufacturer markedForExport monthOfFirstRegistration
					motExpiryDate motStatus registrationNumber vrm revenueWeight taxDueDate taxStatus typeApproval wheelplan wheelPlan yearOfManufacture);

use DateTime;

=head1 SEE ALSO

See L<UK::Vehicle> for usage information.

=head1 METHODS

=over 3

=item result()

Whether the query  against the VES API for information on the vehicle 
was successful. If it wasn't, more information is available using the 
method B<message>().

Returns 1 if successful, 0 otherwise. Successful means a record for the 
vehicle was found and returned. 

=item message()

More information on the success of the query that returned this result. 
For information on possible responses see L<here|https://developer-portal.driver-vehicle-licensing.api.gov.uk/apis/vehicle-enquiry-service/v1.1.0-vehicle-enquiry-service.html#getvehicledetailsbyregistrationnumber-responses>

=item co2Emissions()

The registered CO2 emissions in grammes per km. 

Returns an integer.

=item colour()

The registered colour of the vehicle.

Returns a string.

=cut

sub BUILD
{	
	my ($self, $args) = @_;

	$self->dateOfLastV5CIssued($args->{'dateOfLastV5CIssued'}) if($args->{'dateOfLastV5CIssued'});
	$self->monthOfFirstRegistration($args->{'monthOfFirstRegistration'}) if($args->{'monthOfFirstRegistration'});
	$self->taxDueDate($args->{'taxDueDate'}) if($args->{'taxDueDate'});
	$self->yearOfManufacture($args->{'yearOfManufacture'}) if($args->{'yearOfManufacture'});
	$self->motExpiryDate($args->{'motExpiryDate'}) if($args->{'motExpiryDate'});
}


=pod

=item dateOfLastV5CIssued()

The date the most recent V5 was issued, to the day. This can be helpful in 
determining when it was most revently registered to a new keeper, and 
whether the V5 you have in front of you is the current one. 

Returns a L<DateTime> object. The time portion of this object will be 
set to to 00:00:00, and the timezone "Europe/London."

=cut

sub dateOfLastV5CIssued
{
	my $self = shift;
	my $newval = shift;
	
    if($newval)
    {
		if(ref($newval) eq "DateTime")
		{
			$self->{'dateOfLastV5CIssued'} = $newval;
		}
		else
		{	# Assume YYYY-MM-DD as per data returned by the VES API
			my $new_time = DateTime->new(year => substr($newval, 0, 4), month => substr($newval, 5, 2), day => substr($newval, 8, 2), time_zone => 'Europe/London');
			$new_time->set_hour(1) if $new_time->is_dst;				# Set to 01:00 local if in DST so that when it gets converted back to UTC the date stays the same
			$self->{'dateOfLastV5CIssued'} = $new_time;
		}
    }
	return $self->{'dateOfLastV5CIssued'};
}

=pod

=item engineCapacity()

The engine capacity of any combustion engine fitted in cc. Should be 
undef for electric vehicles.

Returns an integer.

=item euroStatus()

The relevant european emissions standard with which the vehicle complies.

Returns a string.

=item fuelType()

The type of fuel the vehicle uses. he API documentation doesn't
 list this as an enumerated value, so presumably they don't know what's 
 coming over the next ten years and are leaving flexible. Plan for 
 anything! If you've seen other values let me know and I'll add it to 
 the list. Some values currently in use are:

- "PETROL"
- "DIESEL"
- "HYBRID ELECTRIC"
- "ELECTRICITY"
 
Returns a string containing god knows what.

=item make()

=item manufacturer()

The registered manufacturer name of the vehicle. 

Returns a string. 

=cut

# Alias for make
sub manufacturer
{
	my $self = shift;
	my $newval = shift;
	
    if($newval)
    {
		$self->make($newval);
	}
	
	return $self->make;
}

=pod

=item markedForExport()

Whether or not this vehicle has been marked for export - this means 
someone has notified the DVLA of their intention to export it. The 
vehicle is no longer registered in the UK and cannot be taxed, nor can
a V5 be issued for it. It can be MOT tested. 

No information is available as to whether the vehicle has actually been
 exported.

Returns 1 if marked for export, 0 otherwise.

=cut

sub markedForExport
{
	my $self = shift;
	my $newval = shift;
	
    if($newval)
    {
		$self->{'markedForExport'} = $newval;
	}
	
	if($self->{'markedForExport'}) { return 1 };		# Looks pointless but converts JSON::PP::Boolean into 1 or 0
	return 0;
}

=pod

=item monthOfFirstRegistration()

The month in which the vehicle was first registered with the DVLA. This 
is not likely to be the month in which it was manufactured. 

Returns a L<DateTime> object. The day portion of this object will be set
 to the first day of the month, the time portion of this object will be 
set to to 00:00:00, and the timezone "Europe/London."

=cut

sub monthOfFirstRegistration
{
	my $self = shift;
	my $newval = shift;
	
    if($newval)
    {
		if(ref($newval) eq "DateTime")
		{
			$self->{'monthOfFirstRegistration'} = $newval;
		}
		else
		{	# Assume YYYY-MM-DD as per data returned by the VES API
			my $new_time = DateTime->new(year => substr($newval, 0, 4), month => substr($newval, 5, 2), time_zone => 'Europe/London');
			$new_time->set_hour(1) if $new_time->is_dst;				# Set to 01:00 local if in DST so that when it gets converted back to UTC the date stays the same
			$self->{'monthOfFirstRegistration'} = $new_time;
		}
    }
	return $self->{'monthOfFirstRegistration'};
}

=pod

=item motExpiryDate()

The date the current MoT expires, to the day. 

Returns a L<DateTime> object. The time portion of this object will be 
set to to 00:00:00, and the timezone "Europe/London." Returns undef if 
no MoT has been done.

=cut

sub motExpiryDate
{
	my $self = shift;
	my $newval = shift;
	
    if($newval)
    {
		if(ref($newval) eq "DateTime")
		{
			$self->{'motExpiryDate'} = $newval;
		}
		else
		{	# Assume YYYY-MM-DD as per data returned by the VES API
			my $new_time = DateTime->new(year => substr($newval, 0, 4), month => substr($newval, 5, 2), day => substr($newval, 8, 2), time_zone => 'Europe/London');
			$new_time->set_hour(1) if $new_time->is_dst;				# Set to 01:00 local if in DST so that when it gets converted back to UTC the date stays the same
			$self->{'motExpiryDate'} = $new_time;
		}
    }
	return $self->{'motExpiryDate'};
}

=pod

=item motStatus()

A string representing the vehicle's mot test status.

Returns a string with one of these values:
- "No details held by DVLA"
- "No results returned" (don't know the difference)
- "Not valid" (last MoT pass has expired)
- "Valid" (last MoT pass has not expired)

=item registrationNumber

=item vrm

The VRM of the vehicle for which the status information was returned. 
This ought to match the VRM you asked for, with any spaces removed.

Returns a string.

=cut

# Alias for registrationNumber
sub vrm
{
	my $self = shift;
	my $newval = shift;
	
    if($newval)
    {
		$self->registrationNumber($newval);
	}
	
	return $self->registrationNumber;
}

=pod

=item revenueWeight()

The registered "plated gross weight" for the vehicle in kg. See L<The Vehicle 
Excise and Registration Act 1994|https://www.legislation.gov.uk/ukpga/1994/22/section/60A#:~:text=%5BF160A%20Meaning%20of%20%E2%80%9Crevenue%20weight%E2%80%9D.&text=(b)in%20the%20case%20of,travelling%20on%20a%20road%20laden.> 
for more.

Returns an integer.

=item taxDueDate()

The date the road tax is next due to be paid; this does not take into 
account the payment method. Even if the keeper signed up to pay monthly 
by direct debit it will show a date up to 12 months in the future when 
 compared to now().
 
Returns a L<DateTime> object. The time portion of this object will be 
set to to 00:00:00, and the timezone "Europe/London."

=cut

sub taxDueDate
{
	my $self = shift;
	my $newval = shift;
	
    if($newval)
    {
		if(ref($newval) eq "DateTime")
		{
			$self->{'taxDueDate'} = $newval;
		}
		else
		{	# Assume YYYY-MM-DD as per data returned by the VES API
			my $new_time = DateTime->new(year => substr($newval, 0, 4), month => substr($newval, 5, 2), day => substr($newval, 8, 2), time_zone => 'Europe/London');
			$new_time->set_hour(1) if $new_time->is_dst;				# Set to 01:00 local if in DST so that when it gets converted back to UTC the date stays the same
			$self->{'taxDueDate'} = $new_time;
		}
    }
	return $self->{'taxDueDate'};
}

=item taxStatus()

A string representing the vehicle's tax status.

Returns a string with one of these value:
- "Not Taxed for on Road Use" (farm vehicle etc.?)
- "SORN"
- "Taxed" (last MoT pass has expired)
- "Untaxed"

=item typeApproval()

The registered type approval category for the vehicle. You can infer 
some things about the type of vehicle from this; see the 
L<Vehicle Certification Agency's website|https://www.vehicle-certification-agency.gov.uk/vehicle-type-approval/classification-of-power-driven-vehicles-and-trailers/> 
for a list of the categories. 

Returns a 2-character string.

=item wheelplan()
=item wheelPlan()

A description of the number of axles and sometimes the nature of the 
body of the vehicle. 

Returns a string containing god knows what.

=cut

# Alias for wheelplan
sub wheelPlan
{
	my $self = shift;
	my $newval = shift;
	
    if($newval)
    {
		$self->wheelplan($newval);
	}
	
	return $self->wheelplan;
}

=pod 

=item yearOfManufacture()

The month in which the vehicle was manufactured. 

Returns a L<DateTime> object. The month portion of this object will be 
set to the first month of the year, the day portion of this object will 
be set to the first day of the month, the time portion of this object 
will be set to to 00:00:00, and the timezone "Europe/London."

=cut

sub yearOfManufacture
{
	my $self = shift;
	my $newval = shift;
	
    if($newval)
    {
		if(ref($newval) eq "DateTime")
		{
			$self->{'yearOfManufacture'} = $newval;
		}
		else
		{	# Assume year as a number as per data returned by the VES API
			$self->{'yearOfManufacture'} = DateTime->new(year => $newval, time_zone => 'Europe/London');
		}
    }
	return $self->{'yearOfManufacture'};
}

1;
__END__


#~ =item is_mot_current()

   #~ $status->is_mot_current();
   #~ # returns 1 if there is a current, valid MOT. 0 otherwise.
   
#~ This method looks at the property motExpiryDate, and then checks 
#~ whether it is currently "valid". "Valid" means the following is true:
#~ =over 6
#~ =item * The last MoT test result was a pass
#~ =item * The current time in the timezone Europe/London is not 
#~ later than 23:59:59.000 on the expiry date.
#~ =back
#~ B<Yes>, as soon as vehicle fails an MoT, it no longer has a current 
#~ valid MoT even if it not yet one year after the last pass, and you 
#~ cannot legally drive it except under the limited circumstances provided
 #~ for in the relevant law. B<Yes>, your MoT expires right at the very end
#~ of the expiry date so you can drive it right up to midnight on that day.

#~ =item is_tax_current()

   #~ $status->is_tax_current();
   #~ # returns 1 if the vehicle is taxed and can be on the road. 0 
   #~ otherwise
   
#~ This method looks at the property taxStatus, and then checks if it is 
#~ "Taxed". Any status other than this, whether SORNd or untaxed, will 
#~ return 0.

#~ This method will croak if you have not yet called get().

#~ =item is_sorn_declared()

	#~ $status->is_sorn_declared();
	#~ # returns 1 if a SORN has been made for the vehicle. 0 otherwise.

#~ This method looks at the property taxStatus, and then checks if it is 
#~ "SORN". Any status other than this, whether taxed or untaxed, will 
#~ return 0.

#~ This method will croak if you have not yet called get().
   
=back

=head1 BUGS AND REQUESTS

Please report to L<the GitHub repository|https://https://github.com/realflash/perl-mot-history>

=head1 AUTHOR

Ian Gibbs, E<lt>igibbs@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Ian Gibbs

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU GPL version 3.

=cut
