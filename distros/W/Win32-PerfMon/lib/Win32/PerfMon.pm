package Win32::PerfMon;

# Win32::PerfMon.pm
#       +==========================================================+
#       |                                                          |
#       |                     PerfMon.PM package                   |
#       |                     ---------------                      |
#       |                                                          |
#       | Copyright (c) 2004 Glen Small. All rights reserved. 	   |
#       |   This program is free software; you can redistribute    |
#       | it and/or modify it under the same terms as Perl itself. |
#       |                                                          |
#       +==========================================================+
#
#
#	Use under GNU General Public License or Larry Wall's "Artistic License"
#
#	Check the README.TXT file that comes with this package for details about
#	it's history.
#

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

our $VERSION = '0.07';

bootstrap Win32::PerfMon $VERSION;

##########################################
# Constructor
##########################################
sub new
{       
	# The object
	my $self = {};
	
	unless(scalar(@_) == 2)
	{
		croak("You must specify a machine to connect to");
		return(undef);
	}
	
	my($class, $box) = @_;
	
	# Our internal variables.  Should use methods to access
	$self->{'HQUERY'} = undef;
	$self->{'COUNTERS'} = undef;
	$self->{'ERRORMSG'} = undef;
	$self->{'MACHINENAME'} = undef;
	$self->{'CALC_RATE'} = 0;
	
	bless($self, $class);
	
	# Set the box to connect to
	$self->{'MACHINENAME'} = $box;
	
	# Connect to it
        my $res = connect_to_box($self->{'MACHINENAME'}, $self->{'ERRORMSG'});
	
	# See if it worked
	if($res == 0)
	{
		# It did, so try and connect to PDH.dll
		my $RetVal = open_query();
		
		# Now did that work ??
		if($RetVal == -1)
		{
			# Nope
			return undef;
		}
		else
		{
			# Yes, so return the object
			$self->{'HQUERY'} = $RetVal;
						
			return $self;
		}
	}
	else
	{
		# No it didn't so set the error message
		print "Failed to create object [$self->{'ERRORMSG'}]\n";
		return undef;
	}
}

##########################################
# Destructor
##########################################
sub DESTROY
{
	my $self = shift;
	
	# If we have a query object, make sure we free it off
	if(defined($self->{'HQUERY'}))
	{
		CleanUp($self->{'HQUERY'});
		
		$self->{'HQUERY'} = undef;
	}
}


##########################################
# Function to add a  counter to a query
##########################################
sub AddCounter
{	
	# Have we got enough params
	unless(scalar(@_) == 4)
	{
		croak("USAGE: AddCounter(ObjectName, CounterName, InstanceName)");
		return(0);
	}
	
	my ($self, $ObjectName, $CounterName, $Instance) = @_;
	
	# Do we need to handle a rate counter ??
	if($CounterName =~ /\/sec/g)
	{
		$self->{'CALC_RATE'} = 1;
	}
	
	# Default processing, just incase we are dealing with a duplicate counter name ??
	# Could happen if looking at process names such as svchost
	my ($InstanceName, $InstanceNumber) = undef; 
	($InstanceName, $InstanceNumber) = split('\#', $Instance);
	
	# Do we have a instance go look at ?
	unless(defined($InstanceNumber))
	{
		$InstanceNumber = -1;
	}
				
	# go and create the counter ....
        my $NewCounter = add_counter($self->{'MACHINENAME'}, $ObjectName, $CounterName, $InstanceName, $InstanceNumber, $self->{'HQUERY'}, $self->{'ERRORMSG'});
        
        # Return if that didn't work.  Error message will already have been set
        if($NewCounter == -1)
        {			
		return(0);
	}
	
	
	# if it all worked, add it to the internal structure			
        if($InstanceName eq "-1")
        {
                $self->{'COUNTERS'}->{$ObjectName}->{$CounterName}->{'Object'} = $NewCounter;
        }
        else
        {
                $self->{'COUNTERS'}->{$ObjectName}->{$CounterName}->{$Instance}->{'Object'} = $NewCounter;
        }
}

##########################################
# Function to collect the data
##########################################
sub CollectData
{
	my $self = shift;
		
	# Populate the counters associated witht he query object
	my $res = collect_data($self->{'HQUERY'}, $self->{'ERRORMSG'});
	
	if($self->{'CALC_RATE'} == 1 && ($res != -1))
	{	
		sleep(1);

		$res = collect_data($self->{'HQUERY'}, $self->{'ERRORMSG'});
	}
	
	
	if($res == -1)
	{
	    return(0);
	}
	else
	{
	    return(1);
	}
}

##########################################
# Function to return a value
##########################################
sub GetCounterValue
{
	unless(scalar(@_) == 4)
	{
		croak("USAGE: GetCounterValue(ObjectName, CounterName, InstanceName)");
		return(0);
	}
		
	my ($self, $ObjectName, $CounterName, $InstanceName) = @_;
	
	my $RetVal = undef;
		
	# Go and get the value for the reqested counter
	if($InstanceName eq "-1")
	{
		if(exists($self->{'COUNTERS'}->{$ObjectName}->{$CounterName}->{'Object'}))
		{
			$RetVal = collect_counter_value($self->{'HQUERY'}, $self->{'COUNTERS'}->{$ObjectName}->{$CounterName}->{'Object'}, $self->{'ERRORMSG'});	
		}
		else
		{
			$self->{'ERRORMSG'} = "Counter Does Not Exist";
			
			$RetVal = -1;
		}
	}
	else
	{
		$RetVal = collect_counter_value($self->{'HQUERY'}, $self->{'COUNTERS'}->{$ObjectName}->{$CounterName}->{$InstanceName}->{'Object'}, $self->{'ERRORMSG'});
	
		if(exists($self->{'COUNTERS'}->{$ObjectName}->{$CounterName}->{$InstanceName}->{'Object'}))
		{
			$RetVal = collect_counter_value($self->{'HQUERY'}, $self->{'COUNTERS'}->{$ObjectName}->{$CounterName}->{$InstanceName}->{'Object'}, $self->{'ERRORMSG'});	
		}
		else
		{
			$self->{'ERRORMSG'} = "Counter Does Not Exist";
			
			$RetVal = -1;
		}
	}
	
	return($RetVal);
}

##########################################
# Function to close the query
##########################################
sub CloseQuery
{
	my $self = shift;
}

##########################################
# Function to return the error message
sub GetErrorText
{
	my $self = shift;
	
	return($self->{'ERRORMSG'});
}

###########################################
# Function to list the objects
###########################################
sub ListObjects
{
	my $self = shift;
	
	my $Data = list_objects($self->{'MACHINENAME'}, $self->{'ERRORMSG'});
	
	my @Objects = split(/\|/, $Data);
	
	return(\@Objects);
}

###########################################
# Function to list an objects counters
###########################################
sub ListCounters
{
	unless(scalar(@_) == 2)
	{
		croak("Usage: ListCounters(ObjectName)");
		return(0);
	}
	
	my ($self, $Object) = @_;
	
	my $Data = list_counters($self->{'MACHINENAME'}, $Object, $self->{'ERRORMSG'});
	
	my @Counters = split(/\|/, $Data);
	
	if($Counters[0] eq -1)
	{
		return(-1);
	}
	else
	{	
		return(\@Counters);
	}
}

###########################################
# Function to list an objects Instances
###########################################
sub ListInstances
{
	unless(scalar(@_) == 2)
	{
		croak("Usage: ListInstances(ObjectName)");
		return(0);
	}
	
	my ($self, $Object) = @_;
	
	my $Data = list_instances($self->{'MACHINENAME'}, $Object, $self->{'ERRORMSG'});
	
	my @Instances = split(/\|/, $Data);
	
	if($Instances[0] eq -1)
	{
		return(-1);
	}
	else
	{	
		return(\@Instances);
	}
}

###########################################
# Function to explain a counter
###########################################
sub ExplainCounter()
{
    unless(scalar(@_) == 4)
    {
	croak("USAGE: ExplainCounter(ObjectName, CounterName, InstanceName)");
	return(0);
    }
		
	my ($self, $ObjectName, $CounterName, $InstanceName) = @_;
	
	my $RetVal = undef;
		
	# Go and get the value for the reqested counter
	if($InstanceName eq "-1")
	{
		if(exists($self->{'COUNTERS'}->{$ObjectName}->{$CounterName}->{'Object'}))
		{
			$RetVal = explain_counter($self->{'COUNTERS'}->{$ObjectName}->{$CounterName}->{'Object'}, $self->{'ERRORMSG'});	
		}
		else
		{
			$self->{'ERRORMSG'} = "Counter Does Not Exist";
			
			$RetVal = -1;
		}
	}
	else
	{
		if(exists($self->{'COUNTERS'}->{$ObjectName}->{$CounterName}->{$InstanceName}->{'Object'}))
		{
			$RetVal = explain_counter($self->{'COUNTERS'}->{$ObjectName}->{$CounterName}->{$InstanceName}->{'Object'}, $self->{'ERRORMSG'});	
		}
		else
		{
			$self->{'ERRORMSG'} = "Counter Does Not Exist";
			
			$RetVal = -1;
		}
	}
	
	return($RetVal);
}


#############################################
# Function to remove a counter from the query
#############################################
sub RemoveCounter
{
	# Have we got enough params
	unless(scalar(@_) == 4)
	{
		croak("USAGE: AddCounter(ObjectName, CounterName, InstanceName)");
		return(0);
	}
	
	my ($self, $ObjectName, $CounterName, $InstanceName) = @_;
	
	my $RetVal = undef;
			
	# Go and get the value for the reqested counter
	if($InstanceName eq "-1")
	{
		$RetVal = remove_counter($self->{'COUNTERS'}->{$ObjectName}->{$CounterName}->{'Object'}, $self->{'ERRORMSG'});	
		
		if($RetVal == -1)
		{
			return(0);
		}
		else
		{
			delete $self->{'COUNTERS'}->{$ObjectName}->{$CounterName}->{'Object'};
		}
	}
	else
	{
		$RetVal = remove_counter($self->{'COUNTERS'}->{$ObjectName}->{$CounterName}->{$InstanceName}->{'Object'}, $self->{'ERRORMSG'});
		
		if($RetVal == -1)
		{
			return(0);
		}
		else
		{
			delete $self->{'COUNTERS'}->{$ObjectName}->{$CounterName}->{$InstanceName}->{'Object'};
		}
	}	
}


1;
__END__

=head1 NAME

Win32::PerfMon - Perl extension for Windows Perf Monitor (NT4 +)

=head1 SYNOPSIS

  use Win32::PerfMon;
  use strict;
  
  my $ret = undef;
  my $err = undef;
  
  my $xxx = Win32::PerfMon->new("\\\\MyServer");
  
  if($xxx != undef)
  {
  	$ret = $xxx->AddCounter("System", "System Up Time", -1);
  	
  	if($ret != 0)
  	{
  		$ret = $xxx->CollectData();
  		
  		if($ret  != 0)
  		{
  			my $secs = $xxx->GetCounterValue("System", "System Up Time", -1);
  			
  			if($secs > -1)
  			{
  				print "Seconds of Up Time = [$secs]\n";
  			}
  			else
  			{
  				$err = $xxx->GetErrorText();
  				
  				print "Failed to get the counter data ", $err, "\n";
  			}
  		}
  		else
  		{
  			$err = $xxx->GetErrorText();
  							
  			print "Failed to collect the perf data ", $err, "\n";
  		}
  	}
  	else
  	{
  		$err = $xxx->GetErrorText();
  						
  		print "Failed to add the counter ", $err, "\n";
  	}
  }
  else
  {				
  	print "Failed to greate the perf object\n";
}

=head1 DESCRIPTION

This modules provides and interface into the Windows Performance Monitor, which
can be found on any Windows Server from NT 4 onwards.  The module allows the programmer
to add miltiple counters to a query object, and then in a loop, gather the data for those
counters.  This mechanism is very similar to the native windows method.


=head1 METHODS

=head2 NOTE

All functions return 0 (zero) unless stated otherwise.

=over 4

=item new($ServerName)

This is the constructor for the PerfMon perl object.  Calling this function will create
a perl object, as well as calling the underlying WIN32 API code to attach the object
to the windows Performance Monitor.  The function takes as a parameter, the name of the server you
wish to get performance counter on.  Remember to include the leading slashes.

	my $PerfObj = Win32::PerfMon->new("\\\\SERVERNAME");

=item AddCounter($ObjectName, $CounterName, $InstanceName)

This function adds the requested counter to the query obejct.

	$PerfObj->AddCounter("Processor", "% Processor Time", "_Total");
	
Not all counters will have a Instance.  This this case, you would simply substitue the 
Instance with a -1.

If you require performance data onmultiple counter, simply call AddCounter() multiple time, prior
to calling collect data

        # Create the object
        my $PerfObj = Win32::PerfMon->new("\\\\SERVERNAME");

        # Add All the counters
	$PerfObj->AddCounter("System", "System Up Time", -1);
	$PerfObj->AddCounter("System","Context Switches/sec", "-1");
        $PerfObj->AddCounter("System","Processes", "-1");
        $PerfObj->AddCounter("Processor","Interrupts/sec", "_Total");
        
        # Populate the counters from perfmon
        $PerfObj->CollectData()
        
        # Now retrieve the data
        my $value = $PerfObj->GetCounterValue("System", "System Up Time", -1);
        
        etc ....

=item CollectData()

This function when called, will populate the internal structures with the performance data values.
This function should be called after the counters have been added, and before retrieving the counter
values. 

	$PerfObj->CollectData();

=item GetCounterValue($ObjectName, $CounterName, $InstanceName);

This function returns a scaler containing the numeric value for the requested counter.  Befoer calling this
function, you should call CollectData() to populate the internal structures with the relevent data.

	$PerfObj->GetCounterValue("System", "System Up Time", -1);
	
Note that if the counter in question does not have a Instance, you should pass in -1;
You should call this function for every counter you have added, in between calls to CollectData();

GetCounterValue() can be called in a loop and in conjunction with CollectData() if you wish to gather
a series of data, over a period of time.

	# Get the initial values
	$PerfObj->CollectData();
	
	for(1..60)
	{
		# Store the value in question
		my $value = $PerfObj->GetCounterValue("Web", "Current Connections", "_Total");
		
		# Do something with $value - e.g. store it in a DB
		
		# Now update the counter value, so that the next call to GetCounterValue has
		# the updated values
		$PerfObj->CollectData();
	}

=item GetErrorText()

Returns the error message from the last failed function call.

	my $err = $PerfObj->GetErrorText();

=item ListObjects()

Lists all the available performance object on the connected machiene.  NOTE: This function returns
a reference to an array containing the data.  The returned list contains the top level Objetcs.

	my $Data = $PerfObj->ListObjects();
	
	foreach $Object (@$Data)
	{
		print "$Object\n";
	}

=item ListCounter($ObjectName)

Lists all the available performance counters for the specified object on the connected machiene.  
NOTE: This function returns a reference to an array containing the data.  

	my $Data = $PerfObj->ListCounters("System");
	
	foreach $Counter (@$Data)
	{
		print "$Counter\n";
	}

=item ListInstances($ObjectName)

Lists all the available performance counter instances for the specified object on the connected machiene.  
NOTE: This function returns a reference to an array containing the data.  

	my $Data = $PerfObj->ListInstances("System");
	
	foreach $Instance (@$Data)
	{
		print "$Instance\n";
	}

=item RemoveCounter($ObjectName, $CounterName, $InstanceName)

Removes the specifed counter from the query object.  All other defined counte will
remain.  As with other functions, the InstanceName should be replaced with -1 if the Instance
is not required.

	$PerfObj->RemoveCounter("System", "System Up Time", -1);
	
Funtion will return 0 if it didn't work.  Most likley reason for a failure is that the specified
counter had not been defined in the first place.

=item ExplainCounter($ObjectName, $CounterName, $InstanceName)

Returns a string containing the counter description, as defined on the current Windows system.  

	my $CounterText = $PerfObj->ExplainCounter("System", "System Up Time", -1);
	
NOTE: You MUST have added the counter to your object beofre calling this function.  If you don't 
actually want to use the counter, you can simple call RemoveCounter() once the function returns.

=back

=head1 AUTHOR

Glen Small <perl.dev@cyberex.org.uk>



=head1 SEE ALSO



=cut

