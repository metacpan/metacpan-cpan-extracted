#!perl
################################################################################
# $Id: Win32-FTDI-FTD2XX.t,v 1.3 2008/11/17 15:31:02 395502 Exp $
################################################################################

use Test::More tests => 12;

#########################
use strict;
use Win32::FTDI::FTD2XX qw( /./ );

#TEST1
use_ok('Win32::FTDI::FTD2XX');

#TEST2
my $FTD = Win32::FTDI::FTD2XX->new( PFT_DEBUG => 1 );
ok( defined( $FTD ), "new()" );

#TEST3
is( $FTD->PFT_HANDLE(), 1, "PFT_HANDLE()" );

#TEST4
is( $FTD->PFT_STATUS(), FT_OK, "PFT_STATUS()" );

#TEST5
is( $FTD->PFT_STATUS_MSG(), "OK", "PFT_STATUS_MSG()" );

diag( "\n" );

#TEST6
my $modVersion = $FTD->VERSION();
is( $modVersion, "1.04", "VERSION()" );
diag( "FTD2XX::VERSION returns [$modVersion] ... good" );

#TEST7
my $dllVersion = $FTD->P5VERSION();
is( $dllVersion, "1.04", "P5VERSION()" );
diag( "FTD2XX::P5VERSION returns [$dllVersion] ... good" );

#TEST8
my $libraryVersion = $FTD->GetLibraryVersion();
unless( $libraryVersion >= '0030115' )
  {
  die( "FATAL: Your FTD2XX.DLL is too old ($libraryVersion) - please upgrade your FTDI drivers!" );
  }
diag( "GetLibraryVersion() returns: [$libraryVersion] ... good" );
ok( $libraryVersion );

#TEST9
my $numDevices = $FTD->GetNumDevices();
ok( defined( $numDevices ), "GetNumDevices()" );
diag( "GetNumDevices() returns: [$numDevices]" );
unless( $numDevices > 0 )
  {
  diag( "WARNING: You really should plug in an FTDI device for testing!" );
  }
else
  {
  diag( "We'll try to connect to the first FTDI device in the chain (Index 0)" );
  }

# skip the remaining tests, since it requires a device to connect to
SKIP: {
  skip( "No FTDI device detected", 3 ) unless( $numDevices );

#TEST10
my $devOpen = $FTD->OpenByIndex( 0 );
is( $devOpen, 1, "OpenByIndex()" );

#TEST11
my $driverVersion = $FTD->GetDriverVersion();
unless( $driverVersion >= '00020405' )
  {
  die( "FATAL: Your FTDI Driver is too old ($driverVersion) - please upgrade your drivers!" );
  }
diag( "GetDriverVersion() returns: [$driverVersion] ... good" );
ok( $driverVersion );

#TEST12
my $devInfo = $FTD->GetDeviceInfo();
ok( defined( $devInfo ), "GetDeviceInfo()" );
if( $devInfo )
  {
  diag( "GetDeviceInfo() returned:\n" );
  my $out = sprintf( "  Type:\t%d (%s)\n  ID:\t\tVID(%04X) PID(%04X)\n  Serial:\t%s\n  Descr:\t%s\n",
        $devInfo->{TypeID}, $devInfo->{TypeNm}, $devInfo->{VID}, $devInfo->{PID}, $devInfo->{Serial}, $devInfo->{Descr} );
  diag( "$out" );
  }
} # SKIP(numDevices)

__END__

