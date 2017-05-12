#!perl
################################################################################
#
# Description: Perl5 FTDI CDM Driver Interface Module 
#
# Author     : Scott K. MacPherson, (c) Copyright 2008, All Rights Reserved
#              <skmacphe@cpan.org>
#
# $Id: FTD2XX.pm,v 1.4 2008/11/17 15:03:33 395502 Exp $
#
################################################################################

package Win32::FTDI::FTD2XX;

use 5.008008;
use strict;
require Exporter;
use AutoLoader qw(AUTOLOAD);

use Win32::API;       # DLL calling interface

our $VERSION = do { my @r = (q$Revision: 1.4 $ =~ /\d+/g); sprintf( "%d."."%02d" x $#r, @r ) };

use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK );

our @ISA = qw( Exporter );

# default export list
our @EXPORT = qw( 
  FT_OK
);

# available for export to caller
our @EXPORT_OK = qw( 
  FT_OK
  FT_INVALID_HANDLE
  FT_DEVICE_NOT_FOUND
  FT_DEVICE_NOT_OPENED
  FT_IO_ERROR
  FT_INSUFFICIENT_RESOURCES
  FT_INVALID_PARAMETER
  FT_INVALID_BAUD_RATE
  FT_DEVICE_NOT_OPENED_FOR_ERASE
  FT_DEVICE_NOT_OPENED_FOR_WRITE
  FT_FAILED_TO_WRITE_DEVICE
  FT_EEPROM_READ_FAILED
  FT_EEPROM_WRITE_FAILED
  FT_EEPROM_ERASE_FAILED
  FT_EEPROM_NOT_PRESENT
  FT_EEPROM_NOT_PROGRAMMED
  FT_INVALID_ARGS
  FT_NOT_SUPPORTED
  FT_OTHER_ERROR
  FT_DEVICE_LIST_NOT_READY
  PFTE_INVALID_API
  PFTE_MAX_HANDLES
  PFTE_INVALID_HANDLE
  PFTE_WAIT_TIMEOUT
  FT_BAUD_300
  FT_BAUD_600
  FT_BAUD_1200
  FT_BAUD_2400
  FT_BAUD_4800
  FT_BAUD_9600
  FT_BAUD_14400
  FT_BAUD_19200
  FT_BAUD_38400
  FT_BAUD_57600
  FT_BAUD_115200
  FT_BAUD_230400
  FT_BAUD_460800
  FT_BAUD_921600
  FT_BITS_8
  FT_BITS_7
  FT_BITS_6
  FT_BITS_5
  FT_STOP_BITS_1
  FT_STOP_BITS_1_5
  FT_STOP_BITS_2
  FT_PARITY_NONE
  FT_PARITY_ODD
  FT_PARITY_EVEN
  FT_PARITY_MARK
  FT_PARITY_SPACE
  FT_FLOW_NONE
  FT_FLOW_RTS_CTS
  FT_FLOW_DTR_DSR
  FT_FLOW_XON_XOFF
  FT_PURGE_RX
  FT_PURGE_TX
  FT_DEFAULT_RX_TIMEOUT
  FT_DEFAULT_TX_TIMEOUT
  FT_DEVICE_BM
  FT_DEVICE_AM
  FT_DEVICE_100AX
  FT_DEVICE_UNKNOWN
  FT_DEVICE_2232C
  FT_DEVICE_232R
  PFT_FLOW_XonChar
  PFT_FLOW_XoffChar
  PFT_MODEM_STATUS_CTS
  PFT_MODEM_STATUS_DSR
  PFT_MODEM_STATUS_RI
  PFT_MODEM_STATUS_DCD
  PFT_BITMODE_RESET
  PFT_BITMODE_ASYNCBB
  PFT_BITMODE_MPSSE
  PFT_BITMODE_SYNCBB
  PFT_BITMODE_MHBEM
  PFT_BITMODE_FOISM
  PFT_BITMODE_CBUSBB
  PFT_MAX_SERIAL
  PFT_MAX_DESCR
  PFT_MAX_HANDLES
);

#######################################
# Definitions from FTD2XX.H and P5FTD2XX.H

# Specific parameter datatypes
Win32::API::Type->typedef( 'PFT_HANDLE', 'DWORD' );
Win32::API::Type->typedef( 'PPFT_HANDLE', 'LPDWORD' );
Win32::API::Type->typedef( 'PFT_STATUS', 'DWORD' );

# Enumerated device status types
use constant FT_OK => 0;
use constant FT_INVALID_HANDLE => 1;
use constant FT_DEVICE_NOT_FOUND => 2;
use constant FT_DEVICE_NOT_OPENED => 3;
use constant FT_IO_ERROR => 4;
use constant FT_INSUFFICIENT_RESOURCES => 5;
use constant FT_INVALID_PARAMETER => 6;
use constant FT_INVALID_BAUD_RATE => 7;
use constant FT_DEVICE_NOT_OPENED_FOR_ERASE => 8;
use constant FT_DEVICE_NOT_OPENED_FOR_WRITE => 9;
use constant FT_FAILED_TO_WRITE_DEVICE => 10;
use constant FT_EEPROM_READ_FAILED => 11;
use constant FT_EEPROM_WRITE_FAILED => 12;
use constant FT_EEPROM_ERASE_FAILED => 13;
use constant FT_EEPROM_NOT_PRESENT => 14;
use constant FT_EEPROM_NOT_PROGRAMMED => 15;
use constant FT_INVALID_ARGS => 16;
use constant FT_NOT_SUPPORTED => 17;
use constant FT_OTHER_ERROR => 18;
use constant FT_DEVICE_LIST_NOT_READY => 19;
#PFT specific error additions
use constant PFTE_INVALID_API => 100;
use constant PFTE_MAX_HANDLES => 101;
use constant PFTE_INVALID_HANDLE => 102;
use constant PFTE_WAIT_TIMEOUT => 103;

# STATUS Translation - accessed only via PFT_STATUS_MSG()
my %PFTMsg = (
  @{[FT_OK]} => "OK",
  @{[FT_INVALID_HANDLE]} => "FT_INVALID_HANDLE",
  @{[FT_DEVICE_NOT_FOUND]} => "DEVICE_NOT_FOUND",
  @{[FT_DEVICE_NOT_OPENED]} => "DEVICE_NOT_OPENED",
  @{[FT_IO_ERROR]} => "IO_ERROR",
  @{[FT_INSUFFICIENT_RESOURCES]} => "INSUFFICIENT_RESOURCES",
  @{[FT_INVALID_PARAMETER]} => "INVALID_PARAMETER",
  @{[FT_INVALID_BAUD_RATE]} => "INVALID_BAUD_RATE",
  @{[FT_DEVICE_NOT_OPENED_FOR_ERASE]} => "DEVICE_NOT_OPENED_FOR_ERASE",
  @{[FT_DEVICE_NOT_OPENED_FOR_WRITE]} => "DEVICE_NOT_OPENED_FOR_WRITE",
  @{[FT_FAILED_TO_WRITE_DEVICE]} => "FAILED_TO_WRITE_DEVICE",
  @{[FT_EEPROM_READ_FAILED]} => "EEPROM_READ_FAILED",
  @{[FT_EEPROM_WRITE_FAILED]} => "EEPROM_WRITE_FAILED",
  @{[FT_EEPROM_ERASE_FAILED]} => "EEPROM_ERASE_FAILED",
  @{[FT_EEPROM_NOT_PRESENT]} => "EEPROM_NOT_PRESENT",
  @{[FT_EEPROM_NOT_PROGRAMMED]} => "EEPROM_NOT_PROGRAMMED",
  @{[FT_INVALID_ARGS]} => "INVALID_ARGS",
  @{[FT_NOT_SUPPORTED]} => "NOT_SUPPORTED",
  @{[FT_OTHER_ERROR]} => "OTHER_ERROR",
  @{[FT_DEVICE_LIST_NOT_READY]} => "DEVICE_LIST_NOT_READY",
  @{[PFTE_INVALID_API]} => "INVALID_API",
  @{[PFTE_MAX_HANDLES]} => "MAX_HANDLES_REACHED",
  @{[PFTE_INVALID_HANDLE]} => "PFT_INVALID_HANDLE",
  @{[PFTE_WAIT_TIMEOUT]} => "WAIT_TIMEOUT",
  );

# Baud Rates
use constant FT_BAUD_300 => 300;
use constant FT_BAUD_600 => 600;
use constant FT_BAUD_1200 => 1200;
use constant FT_BAUD_2400 => 2400;
use constant FT_BAUD_4800 => 4800;
use constant FT_BAUD_9600 => 9600;
use constant FT_BAUD_14400 => 14400;
use constant FT_BAUD_19200 => 19200;
use constant FT_BAUD_38400 => 38400;
use constant FT_BAUD_57600 => 57600;
use constant FT_BAUD_115200 => 115200;
use constant FT_BAUD_230400 => 230400;
use constant FT_BAUD_460800 => 460800;
use constant FT_BAUD_921600 => 921600;

# Word Lengths
use constant FT_BITS_8 => 0x08;
use constant FT_BITS_7 => 0x07;
use constant FT_BITS_6 => 0x06;
use constant FT_BITS_5 => 0x05;

# Stop Bits
use constant FT_STOP_BITS_1 => 0x00;
use constant FT_STOP_BITS_1_5 => 0x01;
use constant FT_STOP_BITS_2 => 0x02;

# Parity
use constant FT_PARITY_NONE => 0x00;
use constant FT_PARITY_ODD => 0x01;
use constant FT_PARITY_EVEN => 0x02;
use constant FT_PARITY_MARK => 0x03;
use constant FT_PARITY_SPACE => 0x04;

# Flow Control
use constant FT_FLOW_NONE => 0x0000;
use constant FT_FLOW_RTS_CTS => 0x0100;
use constant FT_FLOW_DTR_DSR => 0x0200;
use constant FT_FLOW_XON_XOFF => 0x0400;
use constant PFT_FLOW_XonChar => 0x11;   # CTRL-Q (ANSI standard)
use constant PFT_FLOW_XoffChar => 0x13;  # CTRL-S (ANSI standard)

# Purge rx and tx buffers
use constant FT_PURGE_RX => 1;
use constant FT_PURGE_TX => 2;

# GetModemStatus() flags
use constant PFT_MODEM_STATUS_CTS => 0x00000010;
use constant PFT_MODEM_STATUS_DSR => 0x00000020;
use constant PFT_MODEM_STATUS_RI => 0x00000040;
use constant PFT_MODEM_STATUS_DCD => 0x00000080;

# Get/Set BitMode masks
use constant PFT_BITMODE_RESET => 0x00;
use constant PFT_BITMODE_ASYNCBB => 0x01;
use constant PFT_BITMODE_MPSSE  => 0x02;
use constant PFT_BITMODE_SYNCBB => 0x04;
use constant PFT_BITMODE_MHBEM => 0x08;
use constant PFT_BITMODE_FOISM => 0x10;
use constant PFT_BITMODE_CBUSBB => 0x20;

# Events (NOT IMPLEMENTED IN PERL CODE YET)
#typedef VOID (*PFT_EVENT_HANDLER)(DWORD,DWORD);
#
#my $FT_EVENT_RXCHAR = 1;
#my $FT_EVENT_MODEM_STATUS = 2;

# Timeouts
use constant FT_DEFAULT_RX_TIMEOUT => 300;
use constant FT_DEFAULT_TX_TIMEOUT => 300;

# Enumerated Device types
use constant FT_DEVICE_BM => 0;
use constant FT_DEVICE_AM => 1;
use constant FT_DEVICE_100AX => 2;
use constant FT_DEVICE_UNKNOWN => 3;
use constant FT_DEVICE_2232C => 4;
use constant FT_DEVICE_232R => 5;

# FT Device Translation - accessed only via GetDeviceInfo()
our %FT_DEVICE_TYPE = (
  @{[FT_DEVICE_BM]} => 'FT_DEVICE_BM',
  @{[FT_DEVICE_AM]} => 'FT_DEVICE_AM',
  @{[FT_DEVICE_100AX]} => 'FT_DEVICE_100AX',
  @{[FT_DEVICE_UNKNOWN]} => 'FT_DEVICE_UNKNOWN',
  @{[FT_DEVICE_2232C]} => 'FT_DEVICE_2232C',
  @{[FT_DEVICE_232R]} => 'FT_DEVICE_232R',
  );

# Misc limits
use constant PFT_MAX_SERIAL => 32;     # max serial number string buffer
use constant PFT_MAX_DESCR => 64;      # max description string buffer
use constant PFT_MAX_HANDLES => 50;    # max allocated PFT_HANDLES
use constant PFT_WAIT_POLLTM => 0.25;  # default 250ms wait method poll cycle time

################################################################################
# DLL functions to import (Win32::API parameter/pack syntax) 
# Note: As of this writing, the Win32::API prototype interface from v0.55
# seemed to have issues handling these correctly, and would abort often. 
# However, reverting to the legacy positional/pack parameter interface 
# works fine. 
################################################################################
my $P5FTD2XX_DLL = "p5ftd2xx";

# Note: all functions return L/DWORD type 
my %PFT_Imports = (
  'PFT_Version' => 'P',
  'PFT_New' => 'P',
  'PFT_Free' => 'L',
  'PFT_ValidHandle' => 'L',
  'PFT_Status' => 'L',
  'PFT_GetSerialByIndex' => 'LLP',
  'PFT_GetDescrByIndex' => 'LLP',
  'PFT_OpenByIndex' => 'LL',
  'PFT_OpenBySerial' => 'LP',
  'PFT_Rescan' => 'L',
  'PFT_Reload' => 'LII',
  'PFT_ResetPort' => 'L',
  'PFT_CyclePort' => 'L',
  'PFT_GetDriverVersion' => 'LP',
  'PFT_GetLibraryVersion' => 'LP',
  'PFT_GetNumDevices' => 'LP',
  'PFT_GetDeviceInfo' => 'LPPPP',
  'PFT_Close' => 'L',
  'PFT_SetBaudRate' => 'LL',
  'PFT_SetDivisor' => 'LI',
  'PFT_SetDataCharacteristics' => 'LIII',
  'PFT_SetFlowControl' => 'LIII',
  'PFT_SetTimeouts' => 'LLL',
  'PFT_SetDtr' => 'L',
  'PFT_ClrDtr' => 'L',
  'PFT_SetRts' => 'L',
  'PFT_ClrRts' => 'L',
  'PFT_SetBreakOn' => 'L',
  'PFT_SetBreakOff' => 'L',
  'PFT_GetStatus' => 'LPPP',
  'PFT_GetQueueStatus' => 'LP',
  'PFT_GetModemStatus' => 'LP',
  'PFT_SetChars' => 'LIIII',
  'PFT_SetResetPipeRetryCount' => 'LL',
  'PFT_SetDeadmanTimeout' => 'LL',
  'PFT_StopInTask' => 'L',
  'PFT_RestartInTask' => 'L',
  'PFT_Purge' => 'LL',
  'PFT_ResetDevice' => 'L',
  'PFT_Read' => 'LPLP',
  'PFT_Write' => 'LPLP',
  'PFT_GetLatencyTimer' => 'LP',
  'PFT_SetLatencyTimer' => 'LI',
  'PFT_GetBitMode' => 'LP',
  'PFT_SetBitMode' => 'LII',
  'PFT_SetUSBParameters' => 'LLL',
  );
#
# End of FTD2XX/P5FTD2XX defs
#
################################################################################
# Object Constructor/Destructors
#
sub new
  {
  my $class = shift;
  my $self = {
  # public/user definable settings
  PFT_DEBUG => 0,         # toggles debug output
  @_,
  # private object data
  _PFT_HANDLE => 0,        # handle of opened FTDI device
  _PFT_STATUS => FT_OK,   # status of last PFT call
  _PFT_ERROR => "",        # error message string
  # _{function}            # imported function references
  };
  bless( $self, $class );

  # import the bare minimum from the DLL to get started
  return( $self ) unless( _importDll( $self, "PFT_New" ) );
  return( $self ) unless( _importDll( $self, "PFT_Free" ) );

  my $PFT_HANDLE = pack( 'L', 0 );  # create storage for the handle
  if( $self->{_PFT_STATUS} = $self->{_PFT_New}->Call( $PFT_HANDLE ) )
    {
    return( $self );
    }
  $self->{_PFT_HANDLE} = unpack( 'L', $PFT_HANDLE );
  return( $self ); 

  } # new();

########################################
#
sub DESTROY
  {
  my $self = shift;
  if( $self->{_PFT_Free} && $self->{_PFT_HANDLE} )
    {
    printf( STDERR "Win32::FTDI::DESTROY() Freeing PFT_HANDLE: %d\n", 
            $self->{_PFT_HANDLE} ) if( $self->{PFT_DEBUG} );
    $self->{_PFT_Free}->Call( $self->{_PFT_HANDLE} );
    }
  return( 1 );
  }

################################################################################
# Accessor Methods
#
sub VERSION
  {
  my $self = shift;
  return( $VERSION );  # return our (module) version
  }

########################################
#
sub PFT_HANDLE
  {
  my $self = shift;
  return( $self->{_PFT_HANDLE} );  # return PFT handle number in use
  }

########################################
#
sub PFT_STATUS
  {
  my $self = shift;
  return( $self->{_PFT_STATUS} ); 
  }

########################################
#
sub PFT_STATUS_MSG
  {
  my $self = shift;
  my $PFT_Errno = shift;

  # if specific status translation is not requested, return current
  return( $PFTMsg{$self->{_PFT_STATUS}} ) unless( defined($PFT_Errno) );
  return( $PFTMsg{$PFT_Errno} ); 
  }

########################################
#
sub PFT_ERROR
  {
  my $self = shift;
  return( $self->{_PFT_ERROR} ); 
  }

########################################
#
sub PFT_DEBUG
  {
  my $self = shift;
  my $new = shift;

  if( $new )
    {
    my $old = $self->{PFT_DEBUG};
    $self->{PFT_DEBUG} = $new;
    return( $old );  # return previous debug state
    }
  return( $self->{PFT_DEBUG} );
  }

################################################################################
# Private Object Methods
#
sub _importDll
  {
  my $self = shift;
  my $function = shift;

  # check to make sure we have an import definition for the requested function
  unless( exists( $PFT_Imports{$function} ) )
    {
    $self->{_PFT_STATUS} = PFTE_INVALID_API;
    $self->{_PFT_ERROR} = "No '$function' API in DLL import list";
    return( 0 );   
    }

  # check to make sure we haven't imported this before
  if( $self->{"_$function"} )
    {
    $self->{_PFT_STATUS} = PFTE_INVALID_API;
    $self->{_PFT_ERROR} = "API previously imported";
    return( 0 ); # fail
    }

  # import the function
  print( "Win32::FTDI::_importDll( $function($PFT_Imports{$function}))\n" ) if( $self->{PFT_DEBUG} );
  my $f = Win32::API->new( $P5FTD2XX_DLL, $function, $PFT_Imports{$function}, 'L', '_cdecl' );
  unless( $f )
    {
    $self->{_PFT_STATUS} = PFTE_INVALID_API;
    $self->{_PFT_ERROR} = "$!";
    return( 0 ); # fail
    }

  # store the reference for use
  $self->{"_$function"} = $f;
  return( 1 );   # success

  } # _importDll()

################################################################################
1;
__END__

=pod

=head1 NAME

Win32::FTDI::FTD2XX - PERL5 interface to FTDI's D2XX Direct USB Drivers

=head1 SYNOPSIS

  use Win32::FTDI::FTD2XX qw(:DEFAULT
        FT_BAUD_38400 FT_BITS_8 FT_STOP_BITS_1 FT_PARITY_NONE
        FT_FLOW_RTS_CTS PFT_MODEM_STATUS_CTS
        );

  my $FTD = Win32::FTDI::FTD2XX->new();
  unless( $FTD->PFT_STATUS() == FT_OK )
    {
    printf( STDERR "FTD2XX::new() failed: %s (%s)\n", 
            $FTD->PFT_STATUS_MSG(), $FTD->PFT_ERROR() );
    exit( 1 );
    } 
  printf( "FTD2XX::new() allocated PFT_HANDLE: %d\n", $FTD->PFT_HANDLE() );

  my $numDevices = $FTD->GetNumDevices();
  unless( $FTD->PFT_STATUS() == FT_OK )
    {
    printf( STDERR "FTD2XX::GetNumDevices() failed: %s (%s)\n",  
            $FTD->PFT_STATUS_MSG(), $FTD->PFT_ERROR() );
    exit( 1 );
    } 
  printf( "Found $numDevices FTDI devices connected!\n" );


=head1 DESCRIPTION

Win32::FTDI::FTD2XX provides a Perl5 interface to FTDI's D2XX Direct USB 
Drivers (CDM 2.04.06 as of this writing). It comes in two major components, 
the FTD2XX.pm module and an encapsulation and abstraction library, called
P5FTD2XX.DLL, which wraps the FTDI FTD2XX.DLL, providing a cleaner interface
which works better with Win32::API.

For instance, the simpler parameter passing mechanisms of Win32::API were
never meant to handle things like (de)referencing and passing of pointers to
pointers to buffers etc. The native FT_Open() driver function requires this
to open the device handle, which then becomes the primary identifier for the
connection to the rest of the API routines. Even when trying to pass the
returned pointer around as an opaque datatype when returned through
Win32::API, it fails to be recognized as a valid handle by the FT library,
since the underlying pointer type's value/meaning gets mangled.

The P5FTD2XX Windows DLL abstracts the more complicated API calls and
datatypes (like wrapping 'C<FT_HANDLE>' with 'C<PFT_HANDLE>') and provides 
other extensions to allow Perl to more conveniently interact with the
FTDI devices using the native CDM drivers instead of the Virtual Comm Port
(VCP), which can be problematic on Windows when trying to use older
interfaces like Win32::CommPort or Win32::Serial.

The Win32::FTDI Perl object further abstracts and extends the API to make it
most convenient for the Perl programming space, and looks after allocating &
deallocating the PFT_HANDLEs and packed datatypes for parameter passing. In
general, any export (see EXPORTS below) beginning with 'FT' is a direct Perl
derivative of the original typedef's and #define's from the FTD2XX.H file.
Any export prefixed with 'PFT' is an extension provided by the
Win32::FTDI::FTD2Xxx.pm/P5FTD2XX DLL package.

Many of the native FT API's have been completely preserved, such as
'C<(P)FT_SetDataCharacteristics>', others, like the multi-function 'FT_Open',
have been divided into simpler dedicated interfaces as 'PFT_OpenBySerial'
and 'PFT_OpenByIndex' (Note: The object interface methods do not require the
'PFT_' prefix, except where noted). Other convenience methods have been added,
like 'C<waitForModem( bitmask )>' and the 'crack...' methods which extract
bit fields from FT status bytes for you if you don't care to use the values
directly. 

Note: For performance gains at load time, each object method is autosplit/
autoloaded on demand, at which time each API Method also imports the actual 
API function from the DLL. 

The entire package was developed and tested using an FTDI UM232R USB to 
Serial Bridge device, with an Atmel ATmegaX8 AVR microcontroller backend.


=head1 EXPORTS

The C<FT_OK> status constant is the only default export, as it is the basis 
for testing even the object's C<new()> call. The other symbol exports may be 
chosen as desired on the 'C<use Win32::FTDI::FTD2XX>' line as shown in the 
synopsis.  See the FTD2XX.H header file and the FTD2XX Programmer's Guide for
more information on their values. The PFT specific symbols are explained in the
METHODS section.

The full list of available exports is:
C<FT_OK
  FT_INVALID_HANDLE
  FT_DEVICE_NOT_FOUND
  FT_DEVICE_NOT_OPENED
  FT_IO_ERROR
  FT_INSUFFICIENT_RESOURCES
  FT_INVALID_PARAMETER
  FT_INVALID_BAUD_RATE
  FT_DEVICE_NOT_OPENED_FOR_ERASE
  FT_DEVICE_NOT_OPENED_FOR_WRITE
  FT_FAILED_TO_WRITE_DEVICE
  FT_EEPROM_READ_FAILED
  FT_EEPROM_WRITE_FAILED
  FT_EEPROM_ERASE_FAILED
  FT_EEPROM_NOT_PRESENT
  FT_EEPROM_NOT_PROGRAMMED
  FT_INVALID_ARGS
  FT_NOT_SUPPORTED
  FT_OTHER_ERROR
  FT_DEVICE_LIST_NOT_READY
  PFTE_INVALID_API
  PFTE_MAX_HANDLES
  PFTE_INVALID_HANDLE
  PFTE_WAIT_TIMEOUT
  FT_BAUD_300
  FT_BAUD_600
  FT_BAUD_1200
  FT_BAUD_2400
  FT_BAUD_4800
  FT_BAUD_9600
  FT_BAUD_14400
  FT_BAUD_19200
  FT_BAUD_38400
  FT_BAUD_57600
  FT_BAUD_115200
  FT_BAUD_230400
  FT_BAUD_460800
  FT_BAUD_921600
  FT_BITS_8
  FT_BITS_7
  FT_BITS_6
  FT_BITS_5
  FT_STOP_BITS_1
  FT_STOP_BITS_1_5
  FT_STOP_BITS_2
  FT_PARITY_NONE
  FT_PARITY_ODD
  FT_PARITY_EVEN
  FT_PARITY_MARK
  FT_PARITY_SPACE
  FT_FLOW_NONE
  FT_FLOW_RTS_CTS
  FT_FLOW_DTR_DSR
  FT_FLOW_XON_XOFF
  FT_PURGE_RX
  FT_PURGE_TX
  FT_DEFAULT_RX_TIMEOUT
  FT_DEFAULT_TX_TIMEOUT
  FT_DEVICE_BM
  FT_DEVICE_AM
  FT_DEVICE_100AX
  FT_DEVICE_UNKNOWN
  FT_DEVICE_2232C
  FT_DEVICE_232R
  PFT_FLOW_XonChar
  PFT_FLOW_XoffChar
  PFT_MODEM_STATUS_CTS
  PFT_MODEM_STATUS_DSR
  PFT_MODEM_STATUS_RI
  PFT_MODEM_STATUS_DCD
  PFT_BITMODE_RESET
  PFT_BITMODE_ASYNCBB
  PFT_BITMODE_MPSSE
  PFT_BITMODE_SYNCBB
  PFT_BITMODE_MHBEM
  PFT_BITMODE_FOISM
  PFT_BITMODE_CBUSBB
  PFT_MAX_SERIAL
  PFT_MAX_DESCR
  PFT_MAX_HANDLES
>

=head1 SEE ALSO

You'll probably want a copy of the FTDI D2XX Programmer's Guide to 
reference the corresponding API descriptions ...

http://www.ftdichip.com


=head1 OBJECT METHODS

The following methods have been provided for interaction with the P5FTD2XX and
FTD2XX libraries. All methods set an internal status of type PFT_STATUS, which
will include the values given in the standard FT_STATUS set (i.e. C<$FT_OK> etc), 
as well as PFT specific values, (i.e. PFTE_INVALID_HANDLE). In some cases, if the
method doesn't return some other specific value(s), it will generally return TRUE or
FALSE (or undef) to indicate failure. Note: TRUE and FALSE are loosely bound to 1 and
0 respectively. On failure, the C<PFT_STATUS()> accessor method can be used to query 
the PFT/FT_STATUS error value. C<PFT_ERROR_MSG()> provides a quick string based
translation of the error.

Standard parameter conventions apply: C<{required}, [optional], ...>

In most cases, all numeric parameters are automatically packed and unpacked between
their scalar and binary equivalents for passing into and out of the APIs. Only specific
cases require the application to pack or unpack some datatypes, and will be covered in
those methods. 

=over 2

=item C<New>

=over 2

  Parameters: [PFT_DEBUG => {FALSE|TRUE}]
  Returns: Object Reference (use PFT_STATUS method to check for errors)
  Purpose: Extension Method - Instanciates the FTDI perl object, loads the P5FTD2XX DLL
  and (as a dependency) the FTD2XX DLL. It will immediately import the PFT_New() and 
  PFT_Free() API's as a bare minimum, allocating a PFT_HANDLE type, which is this object
  instance's identifier to the P5FTD2XX library for its lifespan. PFT_HANDLE is synonymous
  with FT_HANDLE, and provides one per object instance. You may allocate a maximum of 
  PFT_MAX_HANDLES objects. 

  The object includes an auto DESTROY method that will close any open FTDI device handle
  and deallocate the PFT_HANDLE in the P5FTD2XX interface, when it gets garbage collected
  by Perl.

  For a description of optional PFT_DEBUG parameter, see the PFT_DEBUG Accessor Method.

=back

=item C<GetNumDevices>

=over 2

  Parameters: None
  Return Success: $numDevices 
  Return Failure: undef
  Purpose: Abstraction Method - Returns the number of connected FTDI devices. 
  See FT_ListDevices().

=back

=item C<Rescan>

=over 2

  Parameters: None
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: API Method - See FT_Rescan()

  Note: As with other bus controls, there is a wait period of 3-5 seconds after
  a USB bus scan where any API call that requires direct connection to the device, 
  like GetSerialByIndex() etc, will fail with FT_INVALID_HANDLE until it has 
  completely stabilized. The application should account for this wait period, or
  setup a polling loop to detect the change in return status.

=back

=item C<Reload>

=over 2

  Parameters: {$devVID, $devPID}
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: API Method - See FT_Reload()

=back

=item C<ResetPort>

=over 2

  Parameters: None
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: API Method - See FT_ResetPort()

=back

=item C<ResetDevice>

=over 2

  Parameters: None
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: API Method - See FT_ResetDevice()

=back

=item C<CyclePort>

=over 2

  Parameters: None
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: API Method - See FT_CyclePort()
  
  Note: As with other bus controls, there is a wait period of 5-8 seconds after
  a CyclePort where any API call that requires direct connection to the device, 
  like GetSerialByIndex() etc, will fail with FT_INVALID_HANDLE until it has 
  completely stabilized. The application should account for this wait period, or
  setup a polling loop to detect the change in return status.

=back

=item C<GetDriverVersion>

=over 2

  Parameters: None
  Return Success: $driverVersion
  Return Failure: undef
  Purpose: API Method - See FT_GetDriverVersion()

=back

=item C<crackDriverVersion>

=over 2

  Parameters: [$driverVersion]
  Return Success: $driverVersionDotNotation
  Return Failure: undef
  Purpose: Convenience method - translates the numeric DWORD from the driver to
  the equivalent dot notation (ie. "00020405" -> "2.04.05"). 
  If $driverVersion is supplied, it should be of the form returned by GetDriverVersion.
  If $driverVersion is undefined, GetDriverVersion will be called first to get the value.

=back

=item C<GetLibraryVersion>

=over 2

  Parameters: None
  Return Success: $libraryVersion
  Return Failure: undef
  Purpose: API Method - See FT_GetLibraryVersion()

=back

=item C<crackLibraryVersion>

=over 2

  Parameters: [$libraryVersion]
  Return Success: $libraryVersionDotNotation
  Return Failure: undef
  Purpose: Convenience method - translates the numeric DWORD from the library to
  the equivalent dot notation (ie. "00030115" -> "3.01.15"). 
  If $libraryVersion is supplied, it should be of the form returned by GetLibraryVersion.
  If $libraryVersion is undefined, GetLibraryVersion will be called first to get the value.

=back

=item C<GetSerialByIndex>

=over 2

  Parameters: {$devIndex}
  Return Success: $devSerial
  Return Failure: undef
  Purpose: Abstraction Method - Returns the serial string of the connected FTDI device
  at the given index. See FT_ListDevices().

=back

=item C<GetDescrByIndex>

=over 2

  Parameters: {$devIndex}
  Return Success: $devDescription
  Return Failure: undef
  Purpose: Abstraction Method - Returns the description string of the connected FTDI device
  at the given index. See FT_ListDevices().

=back

=item C<GetDeviceInfo>

=over 2

  Parameters: {$devIndex}
  Return Success: $devInfo
  Return Failure: undef
  Purpose: Abstraction Method - See FT_GetDeviceInfo(). Returns all the description strings
  via a hash reference of the form:
    $devInfo->{TypeID};  # raw numeric device type ID
    $devInfo->{TypeNm};  # translated TypeID name string
    $devInfo->{VID};     # device's VID
    $devInfo->{PID};     # device's PID
    $devInfo->{Serial};  # serial number string
    $devInfo->{Descr};   # description string

=back

=item C<OpenBySerial>

=over 2

  Parameters: {$devSerial}
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: Abstraction Method - Opens a connection to the device based on serial number.
  See FT_Open(). Note: The object's Close() method should be called to free any previously
  opened FT_HANDLE.

=back

=item C<OpenByIndex>

=over 2

  Parameters: {$devIndex}
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: Abstraction Method - Opens a connection to the device based on index number.
  See FT_Open(). Note: The object's Close() method should be called to free any previously
  opened FT_HANDLE.

=back

=item C<Close>

=over 2

  Parameters: None
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: API Method - See FT_Close().

=back

=item C<SetBaudRate>

=over 2

  Parameters: {$baudRate}
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: API Method - See FT_SetBaudRate().

=back

=item C<SetDivisor>

=over 2

  Parameters: {$divisor}
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: API Method - See FT_SetDivisor().

=back

=item C<SetDataCharacteristics>

=over 2

  Parameters: {$dataBits, $stopBits, $parityBits}
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: API Method - See FT_SetDataCharacteristics().

=back

=item C<SetFlowControl>

=over 2

  Parameters: {$flowCtrl} [, $XonChar, $XoffChar]
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: API Method - See FT_SetFlowControl(). 
  Note: The ANSI standard Xon/Xoff characters have been defined in 
  PFT_FLOW_XonChar (0x11), and PFT_FLOW_XoffChar (0x13).

=back

=item C<SetTimeouts>

=over 2

  Parameters: {$readTimeout, $writeTimeout}
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: API Method - See FT_SetTimeouts(). 

=back

=item C<GetTimeouts>

=over 2

  Parameters: None
  Return Success: $readTimeout, $writeTimeout
  Return Failure: undef
  Purpose: Extension Method - query the current timeout values, as previously set
  in SetTimeouts().

=back

=item C<SetReadTimeout>

=over 2

  Parameters: {$readTimeout}
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: Extension Method - Sets the read timeout without disturbing the current
  write timeout value.

=back


=item C<GetReadTimeout>

=over 2

  Parameters: None
  Return Success: $readTimeout
  Return Failure: undef
  Purpose: Extension Method - Gets the current read timeout value.

=back

=item C<SetWriteTimeout>

=over 2

  Parameters: {$writeTimeout}
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: Extension Method - Sets the write timeout without disturbing the current
  read timeout value.

=back

=item C<GetWriteTimeout>

=over 2

  Parameters: None
  Return Success: $writeTimeout
  Return Failure: undef
  Purpose: Extension Method - Gets the current write timeout value.

=back

=item C<SetDtr>

=over 2

  Parameters: None
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: API Method - See FT_SetDtr().

=back

=item C<ClrDtr>

=over 2

  Parameters: None
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: API Method - See FT_ClrDtr().

=back

=item C<SetRts>

=over 2

  Parameters: None
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: API Method - See FT_SetRts().

=back

=item C<ClrRts>

=over 2

  Parameters: None
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: API Method - See FT_ClrRts().

=back

=item C<SetBreakOn>

=over 2

  Parameters: None
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: API Method - See FT_SetBreakOn().

=back

=item C<SetBreakOff>

=over 2

  Parameters: None
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: API Method - See FT_SetBreakOff().

=back

=item C<GetStatus>

=over 2

  Parameters: None
  Return Success: $amountInRxQueue, $amountInTxQueue, $eventStatus
  Return Failure: undef
  Purpose: API Method - See FT_GetStatus().

=back

=item C<GetQueueStatus>

=over 2

  Parameters: None
  Return Success: $amountInRxQueue
  Return Failure: undef
  Purpose: API Method - See FT_GetQueueStatus().

=back


=item C<GetModemStatus>

=over 2

  Parameters: None
  Return Success: $modemStatus
  Return Failure: undef
  Purpose: API Method - See FT_GetModemStatus().

=back

=item C<crackModemStatus>

=over 2

  Parameters: {$modemStatusBitmask}
  Return Success: $statusCTS, $statusDSR, $statusRI, $statusDCD
  Return Failure: undef
  Purpose: Convenience Method - Based on the provided bitmask, sets each value in the returning
  array to TRUE if bit is set, FALSE otherwise. See FT_GetModemStatus().

=back

=item C<waitForModem>

=over 2

  Parameters: {$modemStatusBitmask} [, $timeout] [, $pollTm]
  Return Success: TRUE
  Return Failure: FALSE (Check PFT_STATUS - FT API failure or PFTE_WAIT_TIMEOUT set)
  Purpose: Extension Method - since the event API's are unimplemented, this method may be used
  to suspend program execution until one or more of the modem status bits is set (see
  GetModemStatus). 

  The modemStatusBitmask is formed using the PFT_MODEM_STATUS_xxx bit definitions. i.e.:
    $FTD->waitForModem( PFT_MODEM_STATUS_CTS, 3 );
  would wait max 3 seconds for the device's CTS signal to assert itself.

  The optional $timeout provides a limiting timeframe to wait, in seconds. Fractional seconds,
  i.e. 0.5 (500ms) are allowed. The timeout is infinite if undefined. 

  The optional $pollTm is the time in seconds between polls of the device. The default is 0.25
  (250ms). 

  Note: the timeout is NOT implemented in real time clock fassion, so it should not be used for
  critical timing sequences, but is accurate enough for most uses. When setting $timeout and/or
  $pollTm, $timeout should be an even multiple of $pollTm, or if not, the overlap in timing should
  be accounted for if neccessary. 

=back

=item C<SetChars>

=over 2

  Parameters: {$eventCh, $eventChEn, $errorCh, $errorChEn}
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: API Method - See FT_SetChars().
  Note: The $eventCh and $errorCh parameters should be specified in numeric form, 
  i.e.:  SetChars( 0x12, 1, 0x14, 1 );

=back

=item C<SetResetPipeRetryCount>

=over 2

  Parameters: {$count}
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: API Method - See FT_SetResetPipeRetryCount().

=back

=item C<StopInTask>

=over 2

  Parameters: None
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: API Method - See FT_StopInTask().

=back

=item C<RestartInTask>

=over 2

  Parameters: None
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: API Method - See FT_RestartInTask().

=back

=item C<Purge>

=over 2

  Parameters: {$mask}
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: API Method - See FT_Purge().

=back

=item C<Read>

=over 2

  Parameters: {$bytesToRead}
  Return Success: $bytesReturned, $readBuffer
  Return Failure: undef
  Purpose: API Method - See FT_Read().
  Note: The method treats the returned buffer content as an opaque scalar value. Any translation
  of strings or unpacking of binary content must be done by the application.

=back

=item C<Write>

=over 2

  Parameters: {$writeBuffer} [, $bytesToWrite]
  Return Success: $bytesWritten
  Return Failure: undef
  Purpose: API Method - See FT_Write().
  Note: The method treats the write buffer content as an opaque scalar value. Any translation
  of strings or packing of binary content must be done by the application.
  If $bytesToWrite is not specified, the method will use the return of 'length($writeBuffer)'.
  If $bytesToWrite is specified, it allows sending a full or partial buffer; however, the result
  of sending more bytes than are in the buffer is undefined.

=back

=item C<GetLatencyTimer>

=over 2

  Parameters: None
  Return Success: $timer
  Return Failure: undef
  Purpose: API Method - See FT_GetLatencyTimer().

=back

=item C<SetLatencyTimer>

=over 2

  Parameters: {$timer}
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: API Method - See FT_SetLatencyTimer().

=back

=item C<GetBitMode>

=over 2

  Parameters: None
  Return Success: $mode
  Return Failure: undef
  Purpose: API Method - See FT_GetBitMode().

=back

=item C<SetBitMode>

=over 2

  Parameters: {$mode}
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: API Method - See FT_SetBitMode().
  Note: The following EXPORTS for BitModes are available for convenience:
    PFT_BITMODE_RESET
    PFT_BITMODE_ASYNCBB
    PFT_BITMODE_MPSSE
    PFT_BITMODE_SYNCBB
    PFT_BITMODE_MHBEM
    PFT_BITMODE_FOISM
    PFT_BITMODE_CBUSBB

=back

=item C<SetUSBParameters>

=over 2

  Parameters: {$inTransferSize, $outTransferSize}
  Return Success: TRUE
  Return Failure: FALSE
  Purpose: API Method - See FT_SetUSBParameters().

=back

=item C<P5VERSION>

=over 2

  Parameters: None
  Return Success: $PFT_DLL_VERSION
  Return Failure: undef
  Purpose: Accesor Method - returns the version of the P5FTD2XX DLL in use.

=back

=item C<VERSION>

=over 2

  Parameters: None
  Return Success: $FTD2XX_MODULE_VERSION
  Return Failure: undef
  Purpose: Accesor Method - returns the version of the FTD2XX.pm in use.

=back

=item C<PFT_HANDLE>

=over 2

  Parameters: None
  Return Success: $PFT_HANDLE
  Return Failure: undef
  Purpose: Accesor Method - returns the numeric PFT_HANDLE allocated by the 
  P5FTD2XX library which identifies the object's unique connection and state
  information store.

=back

=item C<PFT_STATUS>

=over 2

  Parameters: None
  Return Success: $PFT_STATUS
  Return Failure: undef
  Purpose: Accesor Method - returns the enumerated status/error values of the last
  method call (see FT and PFTE extensions in EXPORTS). In addition to the FT status
  types, the PFT specific error types are: 
  PFTE_INVALID_API - Requested API not in P5FTD2XX.DLL - usually a bug on my part, or the
    P5FTD2XX.DLL can't be found in the system PATH (default: "%SystemRoot%\System32")
  PFTE_INVALID_HANDLE - The PFT_HANDLE passed is not valid (also usually a bug on my part)
  PFTE_MAX_HANDLES - You've allocated max objects/PFT_HANDLES from the P5FTD2XX interface
  PFTE_WAIT_TIMEOUT - error type for 'waitForModem' method on timeout only

=back

=item C<PFT_STATUS_MSG>

=over 2

  Parameters: [$PFT_STATUS]
  Return Success: $PFT_STATUS_MSG
  Return Failure: undef
  Purpose: Accesor Method - translates the enumerated FT_STATUS/PFT_STATUS values into
  text equivalent for ease of generating error output. If a specific $PFT_STATUS is not 
  provided, the method assumes the current state.

=back

=item C<PFT_ERROR>

=over 2

  Parameters: None
  Return Success: $PFT_ERROR
  Return Failure: undef
  Purpose: Accesor Method - some methods may have extended error information regarding the
  failure reported in the (P)FT_STATUS types, and are returned here. 

=back

=item C<PFT_DEBUG>

=over 2

  Parameters: {TRUE|FALSE}
  Return Success: $previousState
  Return Failure: undef
  Purpose: Accesor Method - some methods may have extended runtime debug information that
  can be sent to STDERR when this variable is set to TRUE.

=back

=back

=head1 DEPENDENCIES

The FTDI/FTD2XX Drivers, at least CDM 2.04.06, must be installed in conjunction
with this module for it to be functional (and, obviously, to get very far, you'll
need an FTDI device plugged into your USB bus...)

The perl object uses Win32::API (v0.55 on my ActiveState 5.8.8 build) to interface
with the P5FTD2XX DLL.

=head1 BUGS and THINGS TO DO

Please report bugs to me at my email address below.

See the BUGS file in the distribution for known issues and their status.


B<Things to Do>

1) The FT_EVENT features have not been ported, and may or may not be, depending
on demand (see the 'waitForModem' method instead for now).

2) Complete the DeviceInfoList/Detail Classic APIs.

3) Complete the EEPROM API interface.

4) Win the lottery, buy an island and retire ...

AND... if anyone is really just peeing their pants for a particular function that
I haven't provided or ported yet, let me know and I'll see what I can do with the
time I have.


=head1 AUTHOR

Scott K. MacPherson <skmacphe@cpan.org>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Scott K. MacPherson, Akron, Ohio

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

################################################################################
# Autosplit/Autoloaded Object Methods
#
sub P5VERSION
  {
  my $self = shift;
  my $version = "\0" x 32;

  unless( defined( $self->{_PFT_Version} ) )
    {
    return( undef ) unless( _importDll( $self, "PFT_Version" ) );
    }
    
  $self->{_PFT_STATUS} = $self->{_PFT_Version}->Call( $version );
  return( undef ) if( $self->{_PFT_STATUS} );
  
  $version = do { my @r = ($version =~ /\d+/g); sprintf( "%d."."%02d" x $#r, @r ) };
  return( $version );  # return Perl5 FT encapsulation library version in use
  }

########################################
#
sub GetNumDevices
  {
  my $self = shift;

  unless( defined( $self->{_PFT_GetNumDevices} ) )
    {
    return( undef ) unless( _importDll( $self, "PFT_GetNumDevices" ) );
    }

  my $numDevices = pack( 'L', 0 );
  $self->{_PFT_STATUS} = $self->{_PFT_GetNumDevices}->Call( $self->{_PFT_HANDLE}, $numDevices );

  return( undef ) if( $self->{_PFT_STATUS} );
  return( unpack( 'L', $numDevices ) );

  } # GetNumDevices()

########################################
#
sub Rescan
  {
  my $self = shift;

  unless( defined( $self->{_PFT_Rescan} ) )
    {
    return( 0 ) unless( _importDll( $self, "PFT_Rescan" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_Rescan}->Call( $self->{_PFT_HANDLE} );

  return( 0 ) if( $self->{_PFT_STATUS} );
  return( 1 );

  } # Rescan()

########################################
#
sub Reload
  {
  my $self = shift;
  my $devVID = shift;
  my $devPID = shift;

  unless( defined( $self->{_PFT_Reload} ) )
    {
    return( 0 ) unless( _importDll( $self, "PFT_Reload" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_Reload}->Call( $self->{_PFT_HANDLE}, 
                           $devVID, $devPID );

  return( 0 ) if( $self->{_PFT_STATUS} );
  return( 1 );

  } # Reload()

########################################
#
sub ResetPort
  {
  my $self = shift;

  unless( defined( $self->{_PFT_ResetPort} ) )
    {
    return( 0 ) unless( _importDll( $self, "PFT_ResetPort" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_ResetPort}->Call( $self->{_PFT_HANDLE} );

  return( 0 ) if( $self->{_PFT_STATUS} );
  return( 1 );

  } # ResetPort()

########################################
#
sub ResetDevice
  {
  my $self = shift;

  unless( defined( $self->{_PFT_ResetDevice} ) )
    {
    return( 0 ) unless( _importDll( $self, "PFT_ResetDevice" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_ResetDevice}->Call( $self->{_PFT_HANDLE} );

  return( 0 ) if( $self->{_PFT_STATUS} );
  return( 1 );

  } # ResetDevice()

########################################
#
sub CyclePort
  {
  my $self = shift;

  unless( defined( $self->{_PFT_CyclePort} ) )
    {
    return( 0 ) unless( _importDll( $self, "PFT_CyclePort" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_CyclePort}->Call( $self->{_PFT_HANDLE} );

  return( 0 ) if( $self->{_PFT_STATUS} );
  return( 1 );

  } # CyclePort()

########################################
#
sub GetDriverVersion
  {
  my $self = shift;

  unless( defined( $self->{_PFT_GetDriverVersion} ) )
    {
    return( undef ) unless( _importDll( $self, "PFT_GetDriverVersion" ) );
    }

  my $driverVersion = pack( 'L', 0 );
  $self->{_PFT_STATUS} = $self->{_PFT_GetDriverVersion}->Call( $self->{_PFT_HANDLE}, 
                           $driverVersion );
  return( undef ) if( $self->{_PFT_STATUS} );

  $driverVersion = sprintf( "%08X", unpack( 'L', $driverVersion ) );
  return( $driverVersion );

  } # GetDriverVersion()

########################################
#
sub crackDriverVersion
  {
  my $self = shift;
  my $version = shift;

  # crack what's provided, or get driver version otherwise
  $version = GetDriverVersion( $self ) unless( $version );  
  return( undef ) if( $self->{_PFT_STATUS} );
  return( sprintf( "%d.%d.%d", $version =~ /^\d\d(\d\d)(\d\d)(\d\d)/ ) );

  } # crackDriverVersion()

########################################
#
sub GetLibraryVersion
  {
  my $self = shift;

  unless( defined( $self->{_PFT_GetLibraryVersion} ) )
    {
    return( undef ) unless( _importDll( $self, "PFT_GetLibraryVersion" ) );
    }

  my $libraryVersion = pack( 'L', 0 );
  $self->{_PFT_STATUS} = $self->{_PFT_GetLibraryVersion}->Call( $self->{_PFT_HANDLE}, 
                           $libraryVersion );
  return( undef ) if( $self->{_PFT_STATUS} );

  $libraryVersion = sprintf( "%08X", unpack( 'L', $libraryVersion ) );
  return( $libraryVersion );

  } # GetLibraryVersion()

########################################
#
sub crackLibraryVersion
  {
  my $self = shift;
  my $version = shift;

  # crack what's provided, or get library version otherwise
  $version = GetLibraryVersion( $self ) unless( $version );  
  return( undef ) if( $self->{_PFT_STATUS} );
  return( sprintf( "%d.%d.%d", $version =~ /^\d\d(\d\d)(\d\d)(\d\d)/ ) );

  } # crackLibraryVersion()

########################################
#
sub GetSerialByIndex
  {
  my $self = shift;
  my $devIndex = shift;

  unless( defined( $self->{_PFT_GetSerialByIndex} ) )
    {
    return( undef ) unless( _importDll( $self, "PFT_GetSerialByIndex" ) );
    }

  my $devSerial = "\0" x PFT_MAX_SERIAL;
  $self->{_PFT_STATUS} = $self->{_PFT_GetSerialByIndex}->Call( $self->{_PFT_HANDLE}, 
                                  $devIndex, $devSerial );
  return( undef ) if( $self->{_PFT_STATUS} );

  $devSerial =~ s/\0//g;  # clean nulls out of the string
  return( $devSerial );

  } # GetSerialByIndex()

########################################
#
sub GetDescrByIndex
  {
  my $self = shift;
  my $devIndex = shift;

  unless( defined( $self->{_PFT_GetDescrByIndex} ) )
    {
    return( undef ) unless( _importDll( $self, "PFT_GetDescrByIndex" ) );
    }

  my $devDescr = "\0" x PFT_MAX_DESCR;
  $self->{_PFT_STATUS} = $self->{_PFT_GetDescrByIndex}->Call( $self->{_PFT_HANDLE}, 
                                  $devIndex, $devDescr );
  return( undef ) if( $self->{_PFT_STATUS} );

  $devDescr =~ s/\0//g;  # clean nulls out of the string
  return( $devDescr );

  } # GetDescrByIndex()

########################################
#
sub GetDeviceInfo
  {
  my $self = shift;

  unless( defined( $self->{_PFT_GetDeviceInfo} ) )
    {
    return( undef ) unless( _importDll( $self, "PFT_GetDeviceInfo" ) );
    }

  my $devType = pack( 'L', 0 );
  my $devID = pack( 'L', 0 );
  my $devSerial = "\0" x PFT_MAX_SERIAL;
  my $devDescr = "\0" x PFT_MAX_DESCR;

  $self->{_PFT_STATUS} = $self->{_PFT_GetDeviceInfo}->Call( $self->{_PFT_HANDLE}, 
                                 $devType, $devID, $devSerial, $devDescr );
  return( undef ) if( $self->{_PFT_STATUS} );

  $devType = unpack( 'L', $devType );  
  $devID = unpack( 'L', $devID );
  $devSerial =~ s/\0//g;               # clean nulls out of the strings
  $devDescr =~ s/\0//g;

  my $devInfo = {};
  $devInfo->{TypeID} = $devType;
  $devInfo->{TypeNm} = $FT_DEVICE_TYPE{$devType};
  $devInfo->{VID} = ( $devID >> 16 );     # most significant word is VID
  $devInfo->{PID} = ( $devID & 0xFFFF );  # least significant word is PID
  $devInfo->{Serial} = $devSerial;
  $devInfo->{Descr} = $devDescr;
  return( $devInfo );

  } # GetDeviceInfo()

########################################
#
sub OpenBySerial
  {
  my $self = shift;
  my $devSerial = shift;

  unless( defined( $self->{_PFT_OpenBySerial} ) )
    {
    return( 0 ) unless( _importDll( $self, "PFT_OpenBySerial" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_OpenBySerial}->Call( $self->{_PFT_HANDLE},
                                   $devSerial );

  return( 0 ) if( $self->{_PFT_STATUS} );
  return( 1 );

  } # OpenBySerial()

########################################
#
sub OpenByIndex
  {
  my $self = shift;
  my $devIndex = shift;

  unless( defined( $self->{_PFT_OpenByIndex} ) )
    {
    return( 0 ) unless( _importDll( $self, "PFT_OpenByIndex" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_OpenByIndex}->Call( $self->{_PFT_HANDLE}, 
                                   $devIndex );

  return( 0 ) if( $self->{_PFT_STATUS} );
  return( 1 );

  } # OpenByIndex()

########################################
#
sub Close
  {
  my $self = shift;
  unless( defined( $self->{_PFT_Close} ) )
    {
    return( 0 ) unless( _importDll( $self, "PFT_Close" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_Close}->Call( $self->{_PFT_HANDLE} );

  return( 0 ) if( $self->{_PFT_STATUS} );
  return( 1 );

  } # Close()

########################################
#
sub SetBaudRate
  {
  my $self = shift;
  my $baud = shift;

  unless( defined( $self->{_PFT_SetBaudRate} ) )
    {
    return( 0 ) unless( _importDll( $self, "PFT_SetBaudRate" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_SetBaudRate}->Call( $self->{_PFT_HANDLE}, $baud );

  return( 0 ) if( $self->{_PFT_STATUS} );
  return( 1 );

  } # SetBaudRate()

########################################
#
sub SetDivisor
  {
  my $self = shift;
  my $div = shift;

  unless( defined( $self->{_PFT_SetDivisor} ) )
    {
    return( 0 ) unless( _importDll( $self, "PFT_SetDivisor" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_SetDivisor}->Call( $self->{_PFT_HANDLE}, $div );

  return( 0 ) if( $self->{_PFT_STATUS} );
  return( 1 );

  } # SetDivisor()

########################################
#
sub SetDataCharacteristics
  {
  my $self = shift;
  my $dataBits = shift;
  my $stopBits = shift;
  my $parityBits = shift;

  unless( defined( $self->{_PFT_SetDataCharacteristics} ) )
    {
    return( 0 ) unless( _importDll( $self, "PFT_SetDataCharacteristics" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_SetDataCharacteristics}->Call( $self->{_PFT_HANDLE},
                                 $dataBits, $stopBits, $parityBits );

  return( 0 ) if( $self->{_PFT_STATUS} );
  return( 1 );

  } # SetDataCharacteristics()

########################################
#
sub SetFlowControl
  {
  my $self = shift;
  my $flowCtrl = shift;
  my $XonChar = shift;
  my $XoffChar = shift;

  unless( defined( $self->{_PFT_SetFlowControl} ) )
    {
    return( 0 ) unless( _importDll( $self, "PFT_SetFlowControl" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_SetFlowControl}->Call( $self->{_PFT_HANDLE},
                                 $flowCtrl, $XonChar, $XoffChar );

  return( 0 ) if( $self->{_PFT_STATUS} );
  return( 1 );

  } # SetFlowControl()

########################################
#
sub SetTimeouts
  {
  my $self = shift;
  my $readTimeout = shift;
  my $writeTimeout = shift;

  unless( defined( $self->{_PFT_SetTimeouts} ) )
    {
    return( 0 ) unless( _importDll( $self, "PFT_SetTimeouts" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_SetTimeouts}->Call( $self->{_PFT_HANDLE},
                                                          $readTimeout, $writeTimeout );

  return( 0 ) if( $self->{_PFT_STATUS} );

  # store these for use by the individual Set/Get timeout functions
  $self->{_READ_TIMEOUT} = $readTimeout;
  $self->{_WRITE_TIMEOUT} = $writeTimeout;

  return( 1 );

  } # SetTimeouts()

########################################
#
sub GetTimeouts
  {
  my $self = shift;
  my $readTimeout = undef;
  my $writeTimeout = undef;

  # use last timeout value stored by SetTimeouts, if available
  $readTimeout = $self->{_READ_TIMEOUT} if( exists( $self->{_READ_TIMEOUT} ) );
  $writeTimeout = $self->{_WRITE_TIMEOUT} if( exists( $self->{_WRITE_TIMEOUT} ) );

  return( $readTimeout, $writeTimeout );

  } # GetTimeouts()

########################################
#
sub SetReadTimeout
  {
  my $self = shift;
  my $readTimeout = shift;
  my $writeTimeout;

  unless( defined( $self->{_PFT_SetTimeouts} ) )
    {
    return( 0 ) unless( _importDll( $self, "PFT_SetTimeouts" ) );
    }

  # use last write timeout stored by SetTimeouts, if available
  if( exists( $self->{_WRITE_TIMEOUT} ) )
    { $writeTimeout = $self->{_WRITE_TIMEOUT}; }
  else
    { $writeTimeout = 1000; } # default to 1 second otherwise 

  $self->{_PFT_STATUS} = $self->{_PFT_SetTimeouts}->Call( $self->{_PFT_HANDLE},
                                                          $readTimeout, $writeTimeout );
  return( 0 ) if( $self->{_PFT_STATUS} );

  $self->{_READ_TIMEOUT} = $readTimeout;
  return( 1 );

  } # SetReadTimeout()

########################################
#
sub GetReadTimeout
  {
  my $self = shift;

  # use last write timeout stored by SetTimeouts, if available
  return( $self->{_READ_TIMEOUT} ) if( exists( $self->{_READ_TIMEOUT} ) );
  return( undef );

  } # GetReadTimeout()

########################################
#
sub SetWriteTimeout
  {
  my $self = shift;
  my $writeTimeout = shift;
  my $readTimeout;

  unless( defined( $self->{_PFT_SetTimeouts} ) )
    {
    return( 0 ) unless( _importDll( $self, "PFT_SetTimeouts" ) );
    }

  # use last write timeout stored by SetTimeouts, if available
  if( exists( $self->{_READ_TIMEOUT} ) )
    { $readTimeout = $self->{_READ_TIMEOUT}; }
  else
    { $readTimeout = 1000; } # default to 1 second otherwise

  $self->{_PFT_STATUS} = $self->{_PFT_SetTimeouts}->Call( $self->{_PFT_HANDLE},
                                                          $readTimeout, $writeTimeout );
  return( 0 ) if( $self->{_PFT_STATUS} );

  $self->{_WRITE_TIMEOUT} = $writeTimeout;
  return( 1 );

  } # SetWriteTimeout()

########################################
#
sub GetWriteTimeout
  {
  my $self = shift;

  # use last write timeout stored by SetTimeouts, if available
  return( $self->{_WRITE_TIMEOUT} ) if( exists( $self->{_WRITE_TIMEOUT} ) );
  return( undef ); 

  } # GetWriteTimeout()

########################################
#
sub SetDtr
  {
  my $self = shift;

  unless( defined( $self->{_PFT_SetDtr} ) )
    {
    return( 0 ) unless( _importDll( $self, "PFT_SetDtr" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_SetDtr}->Call( $self->{_PFT_HANDLE} );

  return( 0 ) if( $self->{_PFT_STATUS} );
  return( 1 );

  } # SetDtr()

########################################
#
sub ClrDtr
  {
  my $self = shift;

  unless( defined( $self->{_PFT_ClrDtr} ) )
    {
    return( 0 ) unless( _importDll( $self, "PFT_ClrDtr" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_ClrDtr}->Call( $self->{_PFT_HANDLE} );

  return( 0 ) if( $self->{_PFT_STATUS} );
  return( 1 );

  } # ClrDtr()

########################################
#
sub SetRts
  {
  my $self = shift;

  unless( defined( $self->{_PFT_SetRts} ) )
    {
    return( 0 ) unless( _importDll( $self, "PFT_SetRts" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_SetRts}->Call( $self->{_PFT_HANDLE} );

  return( 0 ) if( $self->{_PFT_STATUS} );
  return( 1 );

  } # SetRts()

########################################
#
sub ClrRts
  {
  my $self = shift;

  unless( defined( $self->{_PFT_ClrRts} ) )
    {
    return( 0 ) unless( _importDll( $self, "PFT_ClrRts" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_ClrRts}->Call( $self->{_PFT_HANDLE} );

  return( 0 ) if( $self->{_PFT_STATUS} );
  return( 1 );

  } # ClrRts()

########################################
#
sub SetBreakOn
  {
  my $self = shift;

  unless( defined( $self->{_PFT_SetBreakOn} ) )
    {
    return( 0 ) unless( _importDll( $self, "PFT_SetBreakOn" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_SetBreakOn}->Call( $self->{_PFT_HANDLE} );

  return( 0 ) if( $self->{_PFT_STATUS} );
  return( 1 );

  } # SetBreakOn()

########################################
#
sub SetBreakOff
  {
  my $self = shift;

  unless( defined( $self->{_PFT_SetBreakOff} ) )
    {
    return( 0 ) unless( _importDll( $self, "PFT_SetBreakOff" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_SetBreakOff}->Call( $self->{_PFT_HANDLE} );

  return( 0 ) if( $self->{_PFT_STATUS} );
  return( 1 );

  } # SetBreakOff()

########################################
#
sub GetStatus
  {
  my $self = shift;

  unless( defined( $self->{_PFT_GetStatus} ) )
    {
    return( undef ) unless( _importDll( $self, "PFT_GetStatus" ) );
    }

  my $amountInRxQueue = pack( 'L', 0 );
  my $amountInTxQueue = pack( 'L', 0 );
  my $eventStatus = pack( 'L', 0 );

  $self->{_PFT_STATUS} = $self->{_PFT_GetStatus}->Call( $self->{_PFT_HANDLE},
                                $amountInRxQueue, $amountInTxQueue, $eventStatus );
  return( undef ) if( $self->{_PFT_STATUS} );

  return( unpack( 'L', $amountInRxQueue ), 
          unpack( 'L', $amountInTxQueue ), 
          unpack( 'L', $eventStatus ) );

  } # GetStatus()

########################################
#
sub GetQueueStatus
  {
  my $self = shift;

  unless( defined( $self->{_PFT_GetQueueStatus} ) )
    {
    return( undef ) unless( _importDll( $self, "PFT_GetQueueStatus" ) );
    }

  my $amountInRxQueue = pack( 'L', 0 );

  $self->{_PFT_STATUS} = $self->{_PFT_GetQueueStatus}->Call( $self->{_PFT_HANDLE},
                                $amountInRxQueue );
  return( undef ) if( $self->{_PFT_STATUS} );

  return( unpack( 'L', $amountInRxQueue ) );

  } # GetQueueStatus()

########################################
#
sub GetModemStatus
  {
  my $self = shift;

  unless( defined( $self->{_PFT_GetModemStatus} ) )
    {
    return( undef ) unless( _importDll( $self, "PFT_GetModemStatus" ) );
    }

  my $modemStatus = pack( 'L', 0 );

  $self->{_PFT_STATUS} = $self->{_PFT_GetModemStatus}->Call( $self->{_PFT_HANDLE},
                                $modemStatus );
  return( undef ) if( $self->{_PFT_STATUS} );

  return( unpack( 'L', $modemStatus ) );

  } # GetModemStatus()

########################################
#
sub crackModemStatus
  {
  my $self = shift;
  my $modemStatus = shift;

  $modemStatus = GetModemStatus( $self ) unless( $modemStatus );
  return( undef ) if( $self->{_PFT_STATUS} );

  return( ($modemStatus & PFT_MODEM_STATUS_CTS) ? 1 : 0,
          ($modemStatus & PFT_MODEM_STATUS_DSR) ? 1 : 0,
          ($modemStatus & PFT_MODEM_STATUS_RI)  ? 1 : 0,
          ($modemStatus & PFT_MODEM_STATUS_DCD) ? 1 : 0
        );
  } # GetModemStatus()

########################################
#
sub waitForModem
  {
  my $self = shift;
  my $modemStatus = shift;
  my $timeout = shift;
  my $pollTm = shift;
  my $totalTm = 0;

  while( 1 )
    {
    $pollTm = PFT_WAIT_POLLTM unless( $pollTm );
    my $status = GetModemStatus( $self );
    return( undef ) if( $self->{_PFT_STATUS} );
    return( 1 ) if( $status & $modemStatus );   # found status true

    # else, wait for required time and check again
    select( undef, undef, undef, $pollTm );     # use for sub-second sleep
    if( $timeout ) 
      {
      $totalTm += $pollTm; 
      printf( STDERR "totalTm: $totalTm >= $timeout\n" );
      last if( $totalTm >= $timeout );
      }
    }

  $self->{_PFT_STATUS} = PFTE_WAIT_TIMEOUT; 
  return( 0 );  # timeout

  }  # waitForModem()

########################################
#
sub SetChars
  {
  my $self = shift;
  my $eventCh = shift;
  my $eventChEn = shift;
  my $errorCh = shift;
  my $errorChEn = shift;
   
  unless( defined( $self->{_PFT_SetChars} ) )
    {
    return( undef ) unless( _importDll( $self, "PFT_SetChars" ) );
    }

#  $eventCh = 0x65;
 # $errorCh = 0x66;
  $self->{_PFT_STATUS} = $self->{_PFT_SetChars}->Call( $self->{_PFT_HANDLE},
                                $eventCh, $eventChEn, $errorCh, $errorChEn );
  return( 0 ) if( $self->{_PFT_STATUS} );
  return( 1 );

  } # SetChars()

########################################
#
sub SetResetPipeRetryCount
  {
  my $self = shift;
  my $retryCount = shift;
  
  unless( defined( $self->{_PFT_SetResetPipeRetryCount} ) )
    {
    return( undef ) unless( _importDll( $self, "PFT_SetResetPipeRetryCount" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_SetResetPipeRetryCount}->Call( $self->{_PFT_HANDLE},
                                $retryCount );
  return( 0 ) if( $self->{_PFT_STATUS} );
  return( 1 );

  } # SetResetPipeRetryCount()

########################################
#
sub StopInTask
  {
  my $self = shift;
  
  unless( defined( $self->{_PFT_StopInTask} ) )
    {
    return( undef ) unless( _importDll( $self, "PFT_StopInTask" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_StopInTask}->Call( $self->{_PFT_HANDLE} );
  return( 0 ) if( $self->{_PFT_STATUS} );
  return( 1 );

  } # StopInTask()

########################################
#
sub RestartInTask
  {
  my $self = shift;
  
  unless( defined( $self->{_PFT_RestartInTask} ) )
    {
    return( undef ) unless( _importDll( $self, "PFT_RestartInTask" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_RestartInTask}->Call( $self->{_PFT_HANDLE} );
  return( 0 ) if( $self->{_PFT_STATUS} );
  return( 1 );

  } # RestartInTask()

########################################
#
sub SetDeadmanTimeout
  {
  my $self = shift;
  my $timeout = shift;
  
  unless( defined( $self->{_PFT_SetDeadmanTimeout} ) )
    {
    return( undef ) unless( _importDll( $self, "PFT_SetDeadmanTimeout" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_SetDeadmanTimeout}->Call( $self->{_PFT_HANDLE},
                                                                $timeout );
  return( 0 ) if( $self->{_PFT_STATUS} );
  return( 1 );

  } # SetDeadmanTimeout()

########################################
#
sub Purge
  {
  my $self = shift;
  my $mask = shift;

  unless( defined( $self->{_PFT_Purge} ) )
    {
    return( 0 ) unless( _importDll( $self, "PFT_Purge" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_Purge}->Call( $self->{_PFT_HANDLE}, $mask );
  return( 0 ) if( $self->{_PFT_STATUS} );

  return( 1 );

  } # Purge()

########################################
#
sub Read
  {
  my $self = shift;
  my $bytesToRead = shift;

  unless( defined( $self->{_PFT_Read} ) )
    {
    return( undef ) unless( _importDll( $self, "PFT_Read" ) );
    }
  
  my $buffer = "\0" x ( $bytesToRead * 2 + 2 );  # pad some extra room
  my $bytesReturned = pack( 'L', 0 );
  $self->{_PFT_STATUS} = $self->{_PFT_Read}->Call( $self->{_PFT_HANDLE}, 
                                $buffer, $bytesToRead, $bytesReturned );
  return( undef ) if( $self->{_PFT_STATUS} );

  # we don't know if the buffer is string or binary data, so no manipulation
  # will be done by us.
  #  $buffer =~ s/\0//g;  # clean the nulls out
  return( unpack( 'L', $bytesReturned ), $buffer );

  } # Read()

########################################
#
sub Write
  {
  my $self = shift;
  my $buffer = shift;
  my $bytesToWrite = shift;
  
  unless( defined( $self->{_PFT_Write} ) )
    {
    return( undef ) unless( _importDll( $self, "PFT_Write" ) );
    }

  $bytesToWrite = length( $buffer ) unless( $bytesToWrite );
  
  my $bytesWritten = pack( 'L', 0 );
  $self->{_PFT_STATUS} = $self->{_PFT_Write}->Call( $self->{_PFT_HANDLE}, 
                                $buffer, $bytesToWrite, $bytesWritten );
  return( undef ) if( $self->{_PFT_STATUS} );
  
  return( unpack( 'L', $bytesWritten ) );

  } # Write()

############################################################
# Extended FTD API
############################################################
#
sub GetLatencyTimer
  {
  my $self = shift;
  
  unless( defined( $self->{_PFT_GetLatencyTimer} ) )
    {
    return( undef ) unless( _importDll( $self, "PFT_GetLatencyTimer" ) );
    }

  my $timer = pack( 'I', 0 );
  $self->{_PFT_STATUS} = $self->{_PFT_GetLatencyTimer}->Call( $self->{_PFT_HANDLE}, 
                                $timer );
  return( undef ) if( $self->{_PFT_STATUS} );
  
  return( unpack( 'I', $timer ) );

  } # GetLatencyTimer()

########################################
#
sub SetLatencyTimer
  {
  my $self = shift;
  my $timer = shift;
  
  unless( defined( $self->{_PFT_SetLatencyTimer} ) )
    {
    return( undef ) unless( _importDll( $self, "PFT_SetLatencyTimer" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_SetLatencyTimer}->Call( $self->{_PFT_HANDLE}, 
                                $timer );
  return( 0 ) if( $self->{_PFT_STATUS} );
  return( 1 );

  } # SetLatencyTimer()

########################################
#
sub GetBitMode
  {
  my $self = shift;
  
  unless( defined( $self->{_PFT_GetBitMode} ) )
    {
    return( undef ) unless( _importDll( $self, "PFT_GetBitMode" ) );
    }

  my $mode = pack( 'I', 0 );
  $self->{_PFT_STATUS} = $self->{_PFT_GetBitMode}->Call( $self->{_PFT_HANDLE}, 
                                $mode );
  return( undef ) if( $self->{_PFT_STATUS} );
  
  return( unpack( 'I', $mode ) );

  } # GetBitMode()

########################################
#
sub SetBitMode
  {
  my $self = shift;
  my $mask = shift;
  my $mode = shift;
  
  unless( defined( $self->{_PFT_SetBitMode} ) )
    {
    return( undef ) unless( _importDll( $self, "PFT_SetBitMode" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_SetBitMode}->Call( $self->{_PFT_HANDLE}, 
                                $mask, $mode );
  return( 0 ) if( $self->{_PFT_STATUS} );
  return( 1 );

  } # SetBitMode()

########################################
#
sub SetUSBParameters
  {
  my $self = shift;
  my $inTransferSize = shift;
  my $outTransferSize = shift;
  
  unless( defined( $self->{_PFT_SetUSBParameters} ) )
    {
    return( undef ) unless( _importDll( $self, "PFT_SetUSBParameters" ) );
    }

  $self->{_PFT_STATUS} = $self->{_PFT_SetUSBParameters}->Call( $self->{_PFT_HANDLE}, 
                                $inTransferSize, $outTransferSize );
  return( 0 ) if( $self->{_PFT_STATUS} );
  return( 1 );

  } # SetUSBParameters()

