package Win32::SystemInfo;

require 5.8.0;
use strict;
use warnings;
use Win32::API 0.60;
use Win32::TieRegistry qw(:KEY_);

use vars qw($VERSION);

$VERSION = '0.12';

# Not sure how useful these are anymore -
# may get rid of them soon.
use constant PROCESSOR_ARCHITECTURE_INTEL   => 0;
use constant PROCESSOR_ARCHITECTURE_MIPS    => 1;
use constant PROCESSOR_ARCHITECTURE_ALPHA   => 2;
use constant PROCESSOR_ARCHITECTURE_PPC     => 3;
use constant PROCESSOR_ARCHITECTURE_AMD64   => 9;
use constant PROCESSOR_ARCHITECTURE_UNKNOWN => 0xFFFF;

my %Procedures = ();
my %Types      = ();
my %Structs    = ();

#===========================
my $check_OS = sub ()    # Attempt to make this as private as possible
{
	my $dwPlatformId;
	my $osType;

	if ( !defined( $Types{'OSVERSIONINFO'} ) ) {
		# (See GetVersionEx on MSDN)
		Win32::API::Struct->typedef(
			OSVERSIONINFO => qw{
			  DWORD dwOSVersionInfoSize;
			  DWORD dwMajorVersion;
			  DWORD dwMinorVersion;
			  DWORD dwBuildNumber;
			  DWORD dwPlatformID;
			  TCHAR szCSDVersion[128];
			  }
		);
		$Types{'OSVERSIONINFO'} = 1;
	}

	if ( !defined( $Procedures{'GetVersionEx'} ) ) {
		Win32::API->Import( 'kernel32',
			'BOOL GetVersionEx(LPOSVERSIONINFO lpOSVersionInfo)' )
		  or die
		  "Could not locate kernel32.dll - SystemInfo.pm cannot continue\n";
		$Procedures{'GetVersionEx'} = 1;
	}

	my $OSVERSIONINFO;
	if ( !defined( $Structs{'OSVERSIONINFO'} ) ) {
		$OSVERSIONINFO = Win32::API::Struct->new('OSVERSIONINFO');
		$Structs{'OSVERSIONINFO'} = $OSVERSIONINFO;
	}
	else {
		$OSVERSIONINFO = $Structs{'OSVERSIONINFO'};
	}

	{
		# Ignore Win32::API warnings. It's ugly, but what are you gonna do?
		local $SIG{__WARN__} = sub { };
		$OSVERSIONINFO->{'dwMajorVersion'}      = 0;
		$OSVERSIONINFO->{'dwMinorVersion'}      = 0;
		$OSVERSIONINFO->{'dwBuildNumber'}       = 0;
		$OSVERSIONINFO->{'dwPlatformID'}        = 0;
		$OSVERSIONINFO->{'szCSDVersion'}        = "" x 128;
		$OSVERSIONINFO->{'dwOSVersionInfoSize'} =
			$OSVERSIONINFO->sizeof();

		GetVersionEx($OSVERSIONINFO) or return undef;

		$dwPlatformId = $OSVERSIONINFO->{dwPlatformID};
		if ( $dwPlatformId == 2 ) {
			my $majorVersion = $OSVERSIONINFO->{dwMajorVersion};
			if ( $majorVersion == 4 ) {
				$osType = "WinNT";
			}
			else {
				$osType = "Win2K";
			}
		}
		elsif ( $dwPlatformId == 1 ) { $osType = "Win9x"; }

		return ( $osType ne "" ) ? $osType : undef;
	}
};
#==================

#==================
my $canUse64Bit = sub () {    # Another private sub - see if we can do 64 bit
	eval { my $foo = pack( "Q", 1234 ) };
	return ($@) ? 0 : 1;
};
#==================

#==================
sub MemoryStatus (\%;$) {
	my $return = shift;       #hash to return
	my $ret_type ||= shift || "B";    #what format does the user want?
	my %fmt_types =
	  ( B => 1, KB => 1024, MB => 1024 * 1024, GB => 1024 * 1024 * 1024 );
	my @params = qw(MemLoad TotalPhys AvailPhys TotalPage
	  AvailPage TotalVirtual AvailVirtual);
	my %results;                      #results of fn call
	my $MemFormat;                    #divisor for format
	my $dwMSLength;                   #validator from fn call

	$MemFormat =
	  ( $ret_type =~ /^[BKMG]B?$/ ) ? $fmt_types{$ret_type} : $fmt_types{B};

	# Determine operating system
	return undef unless my $OS = &$check_OS;

	my $use64Bit = &$canUse64Bit;

	if ( ( $OS eq "Win2K" ) && ($use64Bit) ) {
		if ( !defined( $Types{'MEMORYSTATUSEX'} ) ) {

			# (See GlobalMemoryStatusEx on MSDN)
			Win32::API::Struct->typedef(
				MEMORYSTATUSEX => qw{
				  DWORD dwLength;
				  DWORD MemLoad;
				  ULONGLONG TotalPhys;
				  ULONGLONG AvailPhys;
				  ULONGLONG TotalPage;
				  ULONGLONG AvailPage;
				  ULONGLONG TotalVirtual;
				  ULONGLONG AvailVirtual;
				  ULONGLONG AvailExtendedVirtual;
				  }
			);
			$Types{'MEMORYSTATUSEX'} = 1;
		}

		if ( !defined( $Procedures{'GlobalMemoryStatusEx'} ) ) {
			Win32::API->Import( 'kernel32',
				'BOOL GlobalMemoryStatusEx(LPMEMORYSTATUSEX lpMemoryStatusEx)' )
			  or die
			  "Could not locate kernel32.dll - SystemInfo.pm cannot continue\n";
			$Procedures{'GlobalMemoryStatusEx'} = 1;
		}

		my $MEMORYSTATUSEX;
		if ( !defined( $Structs{'MEMORYSTATUSEX'} ) ) {
			$MEMORYSTATUSEX = Win32::API::Struct->new('MEMORYSTATUSEX');
		}
		else {
			$MEMORYSTATUSEX = $Structs{'MEMORYSTATUSEX'};
		}
		$MEMORYSTATUSEX->{dwLength} = $MEMORYSTATUSEX->sizeof();
		$MEMORYSTATUSEX->{MemLoad} = 0;
		$MEMORYSTATUSEX->{TotalPhys} = 0;
		$MEMORYSTATUSEX->{AvailPhys} = 0;
		$MEMORYSTATUSEX->{TotalPage} = 0;
		$MEMORYSTATUSEX->{AvailPage} = 0;
		$MEMORYSTATUSEX->{TotalVirtual} = 0;
		$MEMORYSTATUSEX->{AvailVirtual} = 0;
		$MEMORYSTATUSEX->{AvailExtendedVirtual} = 0;

		GlobalMemoryStatusEx($MEMORYSTATUSEX);

		if ( keys(%$return) == 0 ) {
			foreach (@params) {
				$return->{$_} =
				  ( $_ eq "MemLoad" )
				  ? $MEMORYSTATUSEX->{$_}
				  : $MEMORYSTATUSEX->{$_} / $MemFormat;
			}
		}
		else {
			foreach (@params) {
				$return->{$_} = $MEMORYSTATUSEX->{$_} / $MemFormat
				  unless ( !defined( $return->{$_} ) );
			}
		}
	}
	else {

		if ( !defined( $Types{'MEMORYSTATUS'} ) ) {
			
			# (See GlobalMemoryStatus on MSDN)
			# I had to change some of the types to get the struct to
			# play nicely with Win32::API. The SIZE_T's are actually
			# DWORDS in previous versions of the Win32 API, so this
			# change doesn't hurt anything.
			# The names of the members in the struct are different than
			# in the API to make my life easier, and to keep the same
			# return values this method has always had.
			Win32::API::Struct->typedef(
				MEMORYSTATUS => qw{
				  DWORD dwLength;
				  DWORD MemLoad;
				  DWORD TotalPhys;
				  DWORD AvailPhys;
				  DWORD TotalPage;
				  DWORD AvailPage;
				  DWORD TotalVirtual;
				  DWORD AvailVirtual;
				  }
			);
			$Types{'MEMORYSTATUS'} = 1;
		}

		if ( !defined( $Procedures{'GlobalMemoryStatus'} ) ) {
			Win32::API->Import( 'kernel32',
				'VOID GlobalMemoryStatus(LPMEMORYSTATUS lpMemoryStatus)' )
			  or die
			  "Could not locate kernel32.dll - SystemInfo.pm cannot continue\n";
			$Procedures{'GlobalMemoryStatus'} = 1;
		}

		my $MEMORYSTATUS;
		if ( !defined( $Structs{'MEMORYSTATUS'} ) ) {
			$MEMORYSTATUS = Win32::API::Struct->new('MEMORYSTATUS');
			$Structs{'MEMORYSTATUS'} = $MEMORYSTATUS;
		}
		else {
			$MEMORYSTATUS = $Structs{'MEMORYSTATUS'};
		}
		$MEMORYSTATUS->align('auto');
		$MEMORYSTATUS->{'dwLength'}     = 0;
		$MEMORYSTATUS->{'MemLoad'}      = 0;
		$MEMORYSTATUS->{'TotalPhys'}    = 0;
		$MEMORYSTATUS->{'AvailPhys'}    = 0;
		$MEMORYSTATUS->{'TotalPage'}    = 0;
		$MEMORYSTATUS->{'AvailPage'}    = 0;
		$MEMORYSTATUS->{'TotalVirtual'} = 0;
		$MEMORYSTATUS->{'AvailVirtual'} = 0;

		GlobalMemoryStatus($MEMORYSTATUS);
		return undef if $MEMORYSTATUS->{dwLength} == 0;

		if ( keys(%$return) == 0 ) {
			foreach (@params) {
				$return->{$_} =
				  ( $_ eq "MemLoad" )
				  ? $MEMORYSTATUS->{$_}
				  : $MEMORYSTATUS->{$_} / $MemFormat;
			}
		}
		else {
			foreach (@params) {
				$return->{$_} = $MEMORYSTATUS->{$_} / $MemFormat
				  unless ( !defined( $return->{$_} ) );
			}
		}
	}
	1;
}
#==========================

#==========================
sub ProcessorInfo (;\%) {
	my $allHash = shift;

	# Determine operating system
	return undef unless my $OS = &$check_OS;

	if ( !defined( $Types{'SYSTEM_INFO'} ) ) {

		# (See GetSystemInfo on MSDN)
		Win32::API::Struct->typedef(
			SYSTEM_INFO => qw{
			  WORD wProcessorArchitecture;
			  WORD wReserved;
			  DWORD dwPageSize;
			  UINT_PTR lpMinimumApplicationAddress;
			  UINT_PTR lpMaximumApplicationAddress;
			  DWORD_PTR dwActiveProcessorMask;
			  DWORD dwNumberOfProcessors;
			  DWORD dwProcessorType;
			  DWORD dwAllocationGranularity;
			  WORD wProcessorLevel;
			  WORD wProcessorRevision;
			  }
		);
		$Types{'SYSTEM_INFO'} = 1;
	}

	if ( !defined( $Procedures{'GetSystemInfo'} ) ) {
		Win32::API->Import( 'kernel32',
			'VOID GetSystemInfo(LPSYSTEM_INFO lpSystemInfo)' )
		  or die
		  "Could not locate kernel32.dll - SystemInfo.pm cannot continue\n";
		$Procedures{'GetSystemInfo'} = 1;
	}
	my $SYSTEM_INFO;
	if ( !defined( $Structs{'SYSTEM_INFO'} ) ) {
		$SYSTEM_INFO = Win32::API::Struct->new('SYSTEM_INFO');
		$Structs{'SYSTEM_INFO'} = $SYSTEM_INFO;
	}
	else {
		$SYSTEM_INFO = $Structs{'SYSTEM_INFO'};
	}

	{
		# Ignore Win32::API warnings. It's ugly, but what are you gonna do?
		local $SIG{__WARN__} = sub { };
		$SYSTEM_INFO->{'wProcessorArchitecture'}      = 0;
		$SYSTEM_INFO->{'wReserved'}                   = 0;
		$SYSTEM_INFO->{'dwPageSize'}                  = 0;
		$SYSTEM_INFO->{'lpMinimumApplicationAddress'} = 0;
		$SYSTEM_INFO->{'lpMaximumApplicationAddress'} = 0;
		$SYSTEM_INFO->{'dwActiveProcessorMask'}       = 0;
		$SYSTEM_INFO->{'dwNumberOfProcessors'}        = 0;
		$SYSTEM_INFO->{'dwProcessorType'}             = 0;
		$SYSTEM_INFO->{'dwAllocationGranularity'}     = 0;
		$SYSTEM_INFO->{'wProcessorLevel'}             = 0;
		$SYSTEM_INFO->{'wProcessorRevision'}          = 0;
		GetSystemInfo($SYSTEM_INFO);

		my $proc_type;    # Holds 386,586,PPC, etc
		my $num_proc;     # number of processors

		$num_proc = $SYSTEM_INFO->{dwNumberOfProcessors};
		if ( $OS eq "Win9x" ) {
			$proc_type = $SYSTEM_INFO->{dwProcessorType};
		}
		elsif ( ( $OS eq "WinNT" ) || ( $OS eq "Win2K" ) ) {
			my $proc_level;    # first digit of Intel chip (5,6,etc)
			my $proc_val;
			$proc_val   = $SYSTEM_INFO->{wProcessorArchitecture};
			$proc_level = $SYSTEM_INFO->{wProcessorLevel};

			# $proc_type is the return value of ProcessorInfo
			if ( $proc_val == PROCESSOR_ARCHITECTURE_INTEL ) {
				$proc_type = $proc_level . "86";
			}
			elsif ( $proc_val == PROCESSOR_ARCHITECTURE_AMD64 ) {
				$proc_type = "x64";
			}
			elsif ( $proc_val == PROCESSOR_ARCHITECTURE_MIPS ) {
				$proc_type = "MIPS";
			}
			elsif ( $proc_val == PROCESSOR_ARCHITECTURE_PPC ) {
				$proc_type = "PPC";
			}
			elsif ( $proc_val == PROCESSOR_ARCHITECTURE_ALPHA ) {
				$proc_type = "ALPHA";
			}
			else { $proc_type = "UNKNOWN"; }
		}

		# if a hash was supplied, fill it with all info
		if ( defined($allHash) ) {
			$allHash->{NumProcessors} = $num_proc;
			$Registry->Delimiter("/");
			for ( my $i = 0 ; $i < $num_proc ; $i++ ) {
				my $procinfo = $Registry->Open(
					"LMachine/Hardware/Description/System/CentralProcessor/$i",
					{ Access => KEY_READ() }
				);
				my %prochash;
				$prochash{Identifier}       = $procinfo->{Identifier};
				$prochash{VendorIdentifier} =
				  $procinfo->{VendorIdentifier};
				if ( $OS eq "Win9x" ) {
					$prochash{MHZ} = -1;
				}
				else {
					$prochash{MHZ} = hex $procinfo->{"~MHz"};
				}
				$prochash{ProcessorName} =
				  $procinfo->{ProcessorNameString};
				$allHash->{"Processor$i"} = \%prochash;
			}
		}
		return $proc_type;
	}
}

1;
__END__

=head1 NAME

Win32::SystemInfo - Memory and Processor information on Win32 systems

=head1 SYNOPSIS

    use Win32::SystemInfo;

# Get Memory Information

    my %mHash;
    if (Win32::SystemInfo::MemoryStatus(%mHash))
    {
     ...process results...
    }

    To get specific values:
    my %mHash = (TotalPhys => 0, AvailPhys => 0);
    if (Win32::SystemInfo::MemoryStatus(%mHash))
    {
     ...mHash contains only TotalPhys and AvailPhys values...
    }

    Change the default return value:
    Win32::SystemInfo::MemoryStatus(%mHash,"MB");

# Get Processor Information

    # This usage is considered deprecated
    my $proc = Win32::SystemInfo::ProcessorInfo();

    my %phash;
    Win32::SystemInfo::ProcessorInfo(%phash);
    for (my $i = 0; $i < $phash{NumProcessors}; $i++) {
     print "Speed of processor $i: " . $phash{"Processor$i"}{MHZ} . "MHz\n";
    }

=head1 ABSTRACT

With this module you can get total/free memory on Win32 systems,
including installed RAM (physical memory) and page file. This module will
also let you access processor information, including processor family
(386,486,etc), speed, name, vendor, and revision information.

=head1 DESCRIPTION

=over 4

=item B<MemoryStatus>

B<Win32::SystemInfo::MemoryStatus>(%mHash,[$format]);

   %mHash                      - The hash that will receive the results.
                                 Certain values can be set prior to the
                                 call to retrieve a subset. (See below)
   $format                     - Optional parameter. Used to set the order
                                 of magnitude of the results. (See below)

   Determines the current memory status of a Win32 machine. Populates
   %mHash with the results. Function returns undef on failure.

   Values returned through the hash:
   MemLoad                     - Windows NT 3.1 to 4.0: The percentage of
                                 approximately the last 1000 pages of physical
                                 memory that is in use.
                               - Windows 2000 and later: The approximate percentage of
                                 total physical memory that is in use.
   TotalPhys                   - Total amount of physical memory (RAM).
                               - For Windows 2k and earlier, see CAVEATS below about 
                               - the accuracy of this value.
   AvailPhys                   - Available physical memory (RAM).
   TotalPage                   - Allocated size of page (swap) file.
   AvailPage                   - Available page file memory.
   TotalVirtual                - Total physical + maximum page file.
   AvailVirtual                 - Total amount of available memory.

   Values returned through the hash can also be specified by setting
   them before the function is called.
       my %mHash = (TotalPhys => 0);
       Win32::MemoryInfo::MemoryStatus(%mHash);

   Will return only the total physical memory.

   MemoryStatus return values in bytes by default. This can be changed with
   the $format parameter. Valid values for $format are:
       B        -  Bytes (default)
       KB       -  Kilobytes
       MB       -  Megabytes
       GB       -  Gigabytes

=item B<ProcessorInfo>

$proc = B<Win32::SystemInfo::ProcessorInfo>([%pHash]);

   Determines the processor information of a Win32 computer. Returns a "quick"
   value or undef on failure. Can also populate %pHash with detailed information
   on all processors present in the system.

   $proc                        - THIS VALUE HAS BEEN MADE OBSOLETE
                                - FOR WINDOWS NT AND LATER. RELY ON IT
                                - AT YOUR OWN RISK.
                                - Contains a numerical representation of the
                                - processor level for Intel machines. For
                                - example, a Pentium will return 586.
                                - For non-Intel Windows NT systems, the
                                - possible return values are:
                                - x64: AMD64
                                - PPC: PowerPC
                                - MIPS: MIPS architecture
                                - ALPHA: Alpha architecture
                                - UNKNOWN: Unknown architecture

   %pHash                       - Optional parameter. Will be filled with
                                - information about all processors.

   Values returned through hash:
   NumProcessors                - The number of processors installed
   ProcessorN                   - A hash containing all info for processor N

   Each ProcessorN hash contains the values:
   Identifier                   - The identifier string for the processor
                                - as found in the registry. The computer I'm
                                - currently using returns the string
                                - "x86 Family 6 Model 7 Stepping 3"
   VendorIdentifier             - The vendor name of the processor
   MHZ                          - The speed in MHz of the processor
                                - This is not a calculated value, but the value
                                - that is recorded in the Windows registry.
                                - This value will be -1 for pre Windows NT
                                - systems (95/98/Me). 
   ProcessorName                - The name of the processor, such as
                                - "Intel Pentium", or "AMD Athlon".

   PLEASE read the note about the MHz value in Caveats, below.

=back

No functions are exported.

=head1 INSTALLATION

Installation is simple. Follow these steps:

 perl Makefile.PL
 nmake
 nmake test
 nmake install

Copy the SystemInfo.html file into whatever directory you keep your
documentation in. I haven't figured out yet how to automatically copy
it over, sorry.

Nmake can be downloaded from L<http://download.microsoft.com/download/vc15/Patch/1.52/W95/EN-US/Nmake15.exe>
Alternatively, Strawberry Perl includes dmake that can be used instead.

This module can also be used by simply placing it /Win32 directory 
somewhere in @INC.

This module requires

Win32::API by Aldo Calpini

Win32::TieRegistry by Tye McQueen

=head1 CAVEATS

The information returned by the MemoryStatus function is volatile.
There is no guarantee that two sequential calls to this function
will return the same information.

On 32 bit computers with more than 4 GB of memory, the MemoryStatus function
can return incorrect information. Windows 2000 reports a value of -1
to indicate an overflow. Earlier versions of Windows NT report a value
that is the real amount of memory, modulo 4 GB.

On 32 bit Intel x86 computers with more than 2 GB and less than 4 GB of memory,
the MemoryStatus function will always return 2 GB for TotalPhys.
Similarly, if the total available memory is between 2 and 4 GB, AvailPhys
will be rounded down to 2 GB.

64 bit systems using 64 bit versions of Perl will report the correct amount of 
physical memory.

ProcessorInfo will only return the CPU speed that is reported in the Windows
registry. This module used to include a DLL that performed a CPU speed calculation,
but all of these new-fangled processors caused the code to break. I don't have the
time or energy to rewrite the module so that it will play well with Dual Core,
Hyperthreading, and what else. The value from the registry appears to be accurate
on the machines I've tested this module on. Windows 9x/Me will return values of -1
for processor speed, as their registries don't store the MHz value. If you're using
Win9x/Me and need the MHz value, use an older version of this module. Sorry.

The ProcessorName value is also pulled straight from the registry. Correctly
determining the processor's name requires throwing some assembly at it, and 
if you've read the previous paragraph you'll know that DLL that threw assembly
at the processor has been removed from this module.

All feedback on other configurations is greatly welcomed.

=head1 CHANGES

 0.01 - Initial Release
 0.02 - Fixed CPU speed reporting for Win9x. Module now includes a DLL that
        performs the Win9x CPU speed determination.
 0.03 - Fixed warning "use of uninitialized value" when calling MemoryStatus
        with no size argument.
 0.04 - Fixed "GetValue" error when calling ProcessorInfo as non-admin user
        on WindowsNT
        - Fixed documentation bug: "AvailableVirtual" to "AvailVirtual"
 0.05 - Fixed bug introduced in 0.03 where $format was ignored in
        MemoryStatus. All results were returned in bytes regardless of
        $format parameter.
 0.06 - Added new entry to processor information hash to display the name
        of the processor. WindowsNT and 2K now use the DLL to determine
        CPU speed as well.
 0.07 - Changed contact information. Recompiled DLL to remove some extraneous calls.
 0.08 - Added more definitions for recent CPUs. Added dependency on version 0.40
        of Win32::API. Reworked Win32::API calls. Changed calls in DLL to
        eliminate need to pack and unpack arguments.
 0.09 - Eliminated cpuspd.dll. Should eliminate some of the headaches associated with
        using this module. It should now return CPU info for all flavors of 
        Windows past Win9x without crashing.
 0.10 - Added bug description for Perl Development Kit. Fixed link to ActiveState module
        location.
 0.11 - Suppress warnings that come from Win32::API when running with the -w switch. Fix bug
        (http://rt.cpan.org/Public/Bug/Display.html?id=30894) where memory could grow 
        uncontrollably.
 0.12 - Fix some 64 bit related bugs. Use correct SYSTEM_INFO structure 
        (http://rt.cpan.org/Public/Bug/Display.html?id=59365) and use correct struct size
        (http://rt.cpan.org/Public/Bug/Display.html?id=48008).

=head1 BUGS

For versions 0.09 and forward, there is a compatibility bug with ActiveState's Perl Development
Kit version 6. Apparently the PDK has been designed to expect the cpuspd.dll file to be present and
fails against versions of this module that do not include the DLL anymore. For details on the bug
and workaround instructions, see this URL: L<http://bugs.activestate.com/show_bug.cgi?id=67333>

=head1 VERSION

This man page documents Win32::SystemInfo version 0.12

February 17, 2013.

=head1 AUTHOR

Chad Johnston C<<>cjohnston@megatome.comC<>>

=head1 COPYRIGHT

Copyright (C) 2013 by Chad Johnston. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

=pod SCRIPT CATEGORIES

Win32
Win32/Utilities

=cut
