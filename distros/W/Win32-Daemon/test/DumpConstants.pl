#//////////////////////////////////////////////////////////////////////////////
#//
#//  DumpConstants.pl
#//  Win32::Daemon Perl extension test script employing Callbacks
#//
#//  Copyright (c) 1998-2008 Dave Roth
#//  Courtesy of Roth Consulting
#//  http://www.roth.net/
#//
#//  This file may be copied or modified only under the terms of either 
#//  the Artistic License or the GNU General Public License, which may 
#//  be found in the Perl 5.0 source kit.
#//
#//  2008.03.24  :Date
#//  20080324    :Version
#//////////////////////////////////////////////////////////////////////////////

# Displays all Win32::Daemon constant values.


use Win32::Daemon;

map
{
	my $Value = eval( $_ );
	
	# Only manage numeric values...
	if( $Value =~ /^[\d-]$/ )
	{
		$Constant{name}->{$_} = $Value;
		push( @{$Constant{value}->{$Value}}, $_ );
	}
} qw(

    SERVICE_CONTROL_USER_DEFINED
    SERVICE_NOT_READY
    SERVICE_STOPPED
    SERVICE_RUNNING
    SERVICE_PAUSED
    SERVICE_START_PENDING
    SERVICE_STOP_PENDING
    SERVICE_CONTINUE_PENDING
    SERVICE_PAUSE_PENDING

    SERVICE_CONTROL_NONE
    SERVICE_CONTROL_STOP
    SERVICE_CONTROL_PAUSE
    SERVICE_CONTROL_CONTINUE
    SERVICE_CONTROL_INTERROGATE
    SERVICE_CONTROL_SHUTDOWN
    SERVICE_CONTROL_PARAMCHANGE
    SERVICE_CONTROL_NETBINDADD
    SERVICE_CONTROL_NETBINDREMOVE
    SERVICE_CONTROL_NETBINDENABLE
    SERVICE_CONTROL_NETBINDDISABLE
    SERVICE_CONTROL_DEVICEEVENT
    SERVICE_CONTROL_HARDWAREPROFILECHANGE
    SERVICE_CONTROL_POWEREVENT
    SERVICE_CONTROL_SESSIONCHANGE
    SERVICE_CONTROL_USER_DEFINED
    SERVICE_CONTROL_RUNNING
    SERVICE_CONTROL_PRESHUTDOWN 
    SERVICE_CONTROL_TIMER
    SERVICE_CONTROL_START

    SERVICE_ACCEPT_DEVICEEVENT
    SERVICE_ACCEPT_HARDWAREPROFILECHANGE
    SERVICE_ACCEPT_POWEREVENT
    SERVICE_ACCEPT_SESSIONCHANGE

    USER_SERVICE_BITS_1
    USER_SERVICE_BITS_2
    USER_SERVICE_BITS_3
    USER_SERVICE_BITS_4
    USER_SERVICE_BITS_5
    USER_SERVICE_BITS_6
    USER_SERVICE_BITS_7
    USER_SERVICE_BITS_8
    USER_SERVICE_BITS_9
    USER_SERVICE_BITS_10

    SERVICE_ACCEPT_STOP
    SERVICE_ACCEPT_PAUSE_CONTINUE
    SERVICE_ACCEPT_SHUTDOWN    
    SERVICE_ACCEPT_PARAMCHANGE  
    SERVICE_ACCEPT_NETBINDCHANGE

    SERVICE_WIN32_OWN_PROCESS
    SERVICE_WIN32_SHARE_PROCESS
    SERVICE_KERNEL_DRIVER
    SERVICE_FILE_SYSTEM_DRIVER
    SERVICE_INTERACTIVE_PROCESS

    SERVICE_BOOT_START
    SERVICE_SYSTEM_START
    SERVICE_AUTO_START
    SERVICE_DEMAND_START
    SERVICE_DISABLED

    SERVICE_DISABLED
    SERVICE_ERROR_NORMAL
    SERVICE_ERROR_SEVERE
    SERVICE_ERROR_CRITICAL

	SC_GROUP_IDENTIFIER    

    NO_ERROR
);


print "Sort by name:\n";
foreach my $Name ( sort { $a cmp $b } keys( %{$Constant{name}} ) )
{
	printf( "\t%25s %d\n", $Name, $Constant{name}->{$Name} );
}


print "\n\nSort by value:\n";
foreach my $Value ( sort { $a <=> $b } keys( %{$Constant{value}} ) )
{
	local( $LocalValue ) = $Value;
	local( $LocalValueHex ) = sprintf( "0x%08x", $Value );
	local( $LocalNameList ) = join( " +", sort { $a <=> $b } @{ $Constant{value}->{$Value} } );
	$~ = "SortByValue";
	write;
}



format SortByValue =
	@>>>>>>>>>>  @<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	$LocalValue, $LocalValueHex, $LocalNameList
~							^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<	
							$LocalNameList
~							^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<	
							$LocalNameList
~							^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<	
							$LocalNameList
~							^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<	
							$LocalNameList
~							^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<	
							$LocalNameList
~							^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<	
							$LocalNameList
~							^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<	
							$LocalNameList
~							^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<	
							$LocalNameList
~							^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<	
							$LocalNameList
~							^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<	
							$LocalNameList
~							^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<	
							$LocalNameList
~							^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<	
							$LocalNameList
~							^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<	
							$LocalNameList
~							^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<	
							$LocalNameList
.
