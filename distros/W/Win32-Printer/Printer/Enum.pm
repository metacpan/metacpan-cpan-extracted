#------------------------------------------------------------------------------#
# Win32::Printer::Enum                                                         #
# V 0.0.6 (2005-02-07)                                                         #
# Copyright (C) 2003-2005 Edgars Binans                                        #
#------------------------------------------------------------------------------#

package Win32::Printer::Enum;

use 5.006;
use strict;
use warnings;

use Carp;

require Exporter;

use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD );

$VERSION = '0.0.6';

@ISA = qw( Exporter );

@EXPORT = qw( Printers ENUM_DEFAULT ENUM_CONNECTIONS ENUM_SHARED );

@EXPORT_OK = qw( Drivers Ports Monitors Processors Types Jobs );

use Win32::Printer;

#------------------------------------------------------------------------------#

sub AUTOLOAD {

  my $constname = $AUTOLOAD;
  $constname =~ s/.*:://;

  croak "Unknown Win32::Printer::Enum macro $constname.\n";

}

#------------------------------------------------------------------------------#

sub ENUM_DEFAULT	{  1; }
sub ENUM_LOCAL		{  2; }
sub ENUM_CONNECTIONS	{  4; }
sub ENUM_NAME		{  8; }
sub ENUM_REMOTE		{ 16; }
sub ENUM_SHARED		{ 32; }
sub ENUM_NETWORK	{ 64; }

#------------------------------------------------------------------------------#

sub Printers {

  if ($#_ > 0) { carp "WARNING: Too many actual parameters!\n"; }

  my ($flag_or_server) = @_;

  my ($flag, $server);

  if ((!defined($flag_or_server)) or ($flag_or_server eq "")) {
    $flag = 2;
    $server = "";
  } elsif ($flag_or_server =~ /^\d+$/) {
    $flag = $flag_or_server == 32 ? 2 | $flag_or_server : $flag_or_server;
    $server = "";
  } else {
    $flag = 8;
    $server = $flag_or_server;
  }

  my $return = Win32::Printer::_EnumPrinters($flag, $server);
  unless (defined($return)) {
    croak "ERROR: Cannot enumerate printers! ${\Win32::Printer::_GetLastError()}";
  }

  if (wantarray) {
    my @return;
    my @lines = split(/\n/, $return);
    for my $i (0..$#lines) {
      (
        $return[$i]{ServerName},
        $return[$i]{PrinterName},
        $return[$i]{ShareName},
        $return[$i]{PortName},
        $return[$i]{DriverName},
        $return[$i]{Comment},
        $return[$i]{Location},
        $return[$i]{SepFile},
        $return[$i]{PrintProcessor},
        $return[$i]{Datatype},
        $return[$i]{Parameters},
        $return[$i]{Attributes},
        $return[$i]{Priority},
        $return[$i]{DefaultPriority},
        $return[$i]{StartTime},
        $return[$i]{UntilTime},
        $return[$i]{Status},
        $return[$i]{Jobs},
        $return[$i]{AveragePPM}
      ) = split(/\t/, $lines[$i]);
    }
    return @return;
  } else {
    return $return;
  }

}

sub Drivers {

  if ($#_ > 1) { carp "WARNING: Too many actual parameters!\n"; }

  my $server = shift;
  if (!defined($server)) { $server = ""; }

  my $env = shift;
  if (!defined($env)) { $env = ""; }

  my $return = Win32::Printer::_EnumPrinterDrivers($server, $env);

  unless (defined($return)) {
    croak "ERROR: Cannot enumerate printer drivers! ${\Win32::Printer::_GetLastError()}";
  }

  if (wantarray) {
    my @return;
    my @lines = split(/\n/, $return);
    for my $i (0..$#lines) {
      (
        $return[$i]{Version},
        $return[$i]{Name},
        $return[$i]{Environment},
        $return[$i]{DriverPath},
        $return[$i]{DataFile},
        $return[$i]{ConfigFile},
        $return[$i]{HelpFile}, 
        $return[$i]{DependentFiles},
        $return[$i]{MonitorName},
        $return[$i]{DefaultDataType}
      ) = split(/\t/, $lines[$i]);
      my @depfiles = split(/\*/, $return[$i]{DependentFiles});
      $return[$i]{DependentFiles} = \@depfiles;
    }
    return @return;
  } else {
    return $return;
  }

}

sub Ports {

  if ($#_ > 0) { carp "WARNING: Too many actual parameters!\n"; }

  my $server = shift;
  if (!defined($server)) { $server = ""; }

  my $return = Win32::Printer::_EnumPorts($server);
  unless (defined($return)) {
    croak "ERROR: Cannot enumerate printer ports! ${\Win32::Printer::_GetLastError()}";
  }

  if (wantarray) {
    my @return;
    my @lines = split(/\n/, $return);
    for my $i (0..$#lines) {
      (
        $return[$i]{PortName},
        $return[$i]{MonitorName},
        $return[$i]{Description},
        $return[$i]{PortType}
      ) = split(/\t/, $lines[$i]);
    }
    return @return;
  } else {
    return $return;
  }

}

sub Monitors {

  if ($#_ > 0) { carp "WARNING: Too many actual parameters!\n"; }

  my $server = shift;
  if (!defined($server)) { $server = ""; }

  my $return = Win32::Printer::_EnumMonitors($server);
  unless (defined($return)) {
    croak "ERROR: Cannot enumerate printer monitors! ${\Win32::Printer::_GetLastError()}";
  }

  if (wantarray) {
    my @return;
    my @lines = split(/\n/, $return);
    for my $i (0..$#lines) {
      (
        $return[$i]{Name},
        $return[$i]{Environment},
        $return[$i]{DLLName}
      ) = split(/\t/, $lines[$i]);
    }
    return @return;
  } else {
    return $return;
  }

}

sub Processors {

  if ($#_ > 1) { carp "WARNING: Too many actual parameters!\n"; }

  my $server = shift;
  if (!defined($server)) { $server = ""; }

  my $env = shift;
  if (!defined($env)) { $env = ""; }

  my $return = Win32::Printer::_EnumPrintProcessors($server, $env);
  unless (defined($return)) {
    croak "ERROR: Cannot enumerate print processors! ${\Win32::Printer::_GetLastError()}";
  }

  if (wantarray) {
    my @return = split(/\n/, $return);
    return @return;
  } else {
    return $return;
  }

}

sub Types {

  if ($#_ > 1) { carp "WARNING: Too many actual parameters!\n"; }

  my $server = shift;
  if (!defined($server)) { $server = ""; }

  my $processor = shift;
  if (!defined($processor)) { $processor = "WinPrint"; }

  my $return = Win32::Printer::_EnumPrintProcessorDatatypes($server, $processor);
  unless (defined($return)) {
    croak "ERROR: Cannot enumerate print processor data types! ${\Win32::Printer::_GetLastError()}";
  }

  if (wantarray) {
    my @return = split(/\n/, $return);
    return @return;
  } else {
    return $return;
  }

}

sub Jobs {


  if ($#_ < 2) { croak "ERROR: Not enough actual parameters!\n"; }
  if ($#_ > 2)  { carp "WARNING: Too many actual parameters!\n"; }

  my ($printer, $begin, $end) = @_;
  Win32::Printer::_num($begin);
  Win32::Printer::_num($end);

  my $return = Win32::Printer::_EnumJobs($printer, $begin, $end);
  unless (defined($return)) {
    croak "ERROR: Cannot enumerate print jobs! ${\Win32::Printer::_GetLastError()}";
  }

  if (wantarray) {
    my @return;
    my @lines = split(/\n/, $return);
    for my $i (0..$#lines) {
      (
        $return[$i]{JobId},
        $return[$i]{PrinterName},
        $return[$i]{MachineName},
        $return[$i]{UserName},
        $return[$i]{Document},
        $return[$i]{NotifyName},
        $return[$i]{Datatype},
        $return[$i]{PrintProcessor},
        $return[$i]{Parameters},
        $return[$i]{DriverName},
        $return[$i]{Status},
        $return[$i]{StatusNr},
        $return[$i]{Priority},
        $return[$i]{Position},
        $return[$i]{StartTime},
        $return[$i]{UntilTime},
        $return[$i]{TotalPages},
        $return[$i]{Size},
        $return[$i]{PagesPrinted}
      ) = split(/\t/, $lines[$i]);
    }
    return @return;
  } else {
    return $return;
  }

}

#------------------------------------------------------------------------------#

1;

__END__

=head1 NAME

Win32::Printer::Enum - Perl extension for Win32 printing environment enumeration

=head1 SYNOPSIS

 use Win32::Printer::Enum;
 use Win32::Printer::Enum qw( Jobs );

 my @printer = Printers();
 @jobs = Jobs($printer[0]{PrinterName}, 0, 1);
 print $jobs[0]{Document};

=head1 ABSTRACT

Win32 printing environment enumeration

=head1 INSTALLATION

See L<Win32::Printer>! This module depends on it.

=head1 DESCRIPTION

Only L</Printers> and its constants are exported by default.

All functions returns tab-delimited tables of values in scalar context or arrays
of hashes in array context. See function descriptions for hash keys and table
column order!

=head2 Printers

  Printers([$flags]);

  or

  Printers([$server]);

The B<Printers> function enumerates available printers, print servers, domains,
or print providers. B<$server> name of the server on which the printer drivers
should be enumerated. If there is no arguments- enumerates locally installed
printers.

B<$flags:>

  ENUM_DEFAULT			=  1

Windows 9X/ME: The function returns information about the default printer.

  ENUM_CONNECTIONS		=  4

Windows NT: The function enumerates the list of printers to which the user
has made previous connections.

  ENUM_SHARED			= 32

The function enumerates printers that have the shared attribute.

B<Return keys in table order:>

 {ServerName}
             String identifying the server that controls the printer. If
             this string is NULL, the printer is controlled locally.

 {PrinterName}
              String that specifies the name of the printer.

 {ShareName}
            String that identifies the sharepoint for the printer.

 {PortName}
           String that identifies the port(s) used to transmit data to the
           printer. If a printer is connected to more than one port, the
           names of each port must be separated by commas (for example,
           "LPT1:,LPT2:,LPT3:"). 

 {DriverName}
             String that specifies the name of the printer driver.

 {Comment}
          String that provides a brief description of the printer.

 {Location}
           String that specifies the physical location of the printer (for
           example, "Bldg. 38, Room 1164").

 {SepFile}
          String that specifies the name of the file used to create the
          separator page. This page is used to separate print jobs sent to
          the printer.

 {PrintProcessor}
                 String that specifies the name of the print processor used
                 by the printer.

 {Datatype}
           String that specifies the data type used to record the print job.

 {Parameters}
             String that specifies the default print-processor parameters.

 {Attributes}
             Specifies the printer attributes. This member can be one of
             the following values:

             0x0001 - Queued
             0x0002 - Direct
             0x0004 - Default (Windows 9X/ME)
             0x0008 - Shared
             0x0080 - Enable DEVQ
             0x0100 - Keep printed jobs
             0x0200 - Do complete first
             0x0400 - Work offline (Windows 9X/ME)
             0x0800 - Enable BIDI (Windows 9X/ME)
             0x2000 - Published in the directory service
                      (Windows NT 5.0 and later)

 {Priority}
           Specifies a priority value that the spooler uses to route print
           jobs. This member can be in the range between 1 through 99.

 {DefaultPriority}
                  Specifies the default priority value assigned to each
                  print job. This member can be in the range between 1
                  through 99.

 {StartTime}
            Specifies the earliest time at which the printer will print a
            job. This value is expressed as minutes elapsed since
            12:00 A.M. GMT (Greenwich Mean Time).

 {UntilTime}
            Specifies the latest time at which the printer will print a job.
            This value is expressed as minutes elapsed since
            12:00 A.M. GMT (Greenwich Mean Time).

 {Status}
         0x00000001 - Paused
         0x00000002 - Error
         0x00000004 - Pending deletion
         0x00000008 - Paper jam
         0x00000010 - Paper out
         0x00000020 - Manual feed
         0x00000040 - Paper problem
         0x00000080 - Offline
         0x00000100 - IO active
         0x00000200 - Busy
         0x00000400 - Printing
         0x00000800 - Output bin full
         0x00001000 - Not available
         0x00002000 - Waiting
         0x00004000 - Processing
         0x00008000 - Initializing
         0x00010000 - Warming up
         0x00020000 - Toner low
         0x00040000 - No toner
         0x00080000 - Page "punted" (not printed) because it is too complex
                      for the printer to print.
         0x00100000 - User intervention
         0x00200000 - Out of memory
         0x00400000 - Door open

 {Jobs}
       Specifies the number of print jobs that have been queued for the
       printer.

 {AveragePPM}
             Specifies the average number of pages per minute that have been
             printed on the printer.

=head2 Jobs

  Jobs($printer_name, $begin, $end);

The B<Jobs> function retreives data describing the specified print jobs for the
specified printer. B<$printername> is friendly printer name. B<$begin & $end>
sets first and last job to enumerate (starting with 0).

B<Return keys in table order:>

 {JobId}
        Specifies a job identifier value.

 {PrinterName}
              String that specifies the name of the printer for which the
              job is spooled.

 {MachineName}
              String that specifies the name of the machine that created the
              print job.

 {UserName}
           String that specifies the name of the user who owns the print
           job.

 {Document}
           String that specifies the name of the print job (for example,
           "MS-WORD: Review.doc").

 {NotifyName}
             String that specifies the name of the user who should be
             notified when the job has been printed or when an error occurs
             while printing the job. 

 {Datatype}
           String that specifies the type of data used to record the print
           job.

 {PrintProcessor}
                 String that specifies the name of the print processor that
                 should be used to print the job.

 {Parameters}
             String that specifies print-processor parameters.

 {DriverName}
             String that specifies the name of the printer driver that
             should be used to process the print job.

 {Status}
         String that specifies the status of the print job. This member
         should be checked prior to StatusNr and, if Status is NULL, the
         status is defined by the contents of the StatusNr member.

 {StatusNr}
           Specifies the job status. This member can be one or more of the
           following values:

           0x0001 - Pasued
           0x0002 - Error
           0x0004 - Deleting
           0x0008 - Spooling
           0x0010 - Printing
           0x0020 - Offline
           0x0040 - Paperout
           0x0080 - Printed

 {Priority}
           Specifies the job priority. This member can be in the range
           between 1 through 99.

 {Position}
           Specifies the job's position in the print queue.

 {StartTime}
            Specifies the earliest time that the job can be printed. This
            value is expressed as minutes elapsed since 12:00 A.M. GMT
            (Greenwich Mean Time).

 {UntilTime}
            Specifies the the latest time that the job can be printed.
            Time in minutes of GMT day. This value is expressed as minutes
            elapsed since 12:00 A.M. GMT (Greenwich Mean Time).

 {TotalPages}
             Specifies the number of pages required for the job.

 {Size}
       Specifies the size, in bytes, of the job.

 {PagesPrinted}
               Specifies the number of pages that have printed.

=head2 Drivers

  Drivers([$server, [$environment]]);

The B<Drivers> function enumerates all of the printer drivers installed on the
specified printer server. B<$server> name of the server on which the printer
drivers should be enumerated. B<$environment> specifies the environment (for
example, "Windows NT x86", "Windows NT R4000", "Windows NT Alpha_AXP", or
"Windows 4.0").

B<Return keys in table order:>

 {Version}
          Specifies a printer-driver version number. 

 {Name}
       String that specifies the name of the driver (for example,
       "QMS 810").

 {Environment}
              String that specifies the environment for which the driver was
              written (for example, "Windows NT x86", "Windows NT R4000",
              "Windows NT Alpha_AXP", or "Windows 4.0").

 {DriverPath}
             String that specifies a filename or full path and filename for
             the file that contains the device driver (for example,
             "C:\DRIVERS\PSCRIPT.DLL").

 {DataFile}
           String that specifies a filename or a full path and filename for
           the file that contains driver data (for example,
           "C:\DRIVERS\QMS810.PPD").

 {ConfigFile}
             String that specifies a filename or a full path and filename
             for the device driver's configuration dynamic-link library (for
             example, "C:\DRIVERS\PSCRPTUI.DLL").

 {HelpFile}
           String that specifies a filename or a full path and filename for
           the device driver's help file.

 {DependentFiles}
                 Array that specifies the files the driver is dependent on.

 {MonitorName}
              String that specifies a language monitor (for example, "PJL
              monitor"). This member can be NULL and should be specified
              only for printers capable of bidirectional communication.

 {DefaultDataType}
                  String that specifies the default data type of the print
                  job (for example, "EMF").

=head2 Ports

  Ports([$server]);

The B<Ports> function enumerates the ports that are available for printing on a
specified server.  B<$server> name of the server on which the printer drivers
should be enumerated.

B<Return keys in table order:>

 {PortName}
           String that identifies a supported printer port (for example,
           "LPT1:").

 {MonitorName}
              String that identifies an installed monitor (for example, "PJL
              monitor").

 {Description}
              String that describes the port in more detail (for example, if
              PortName is "LPT1:", Description is "printer port").

 {PortType}
           Handle to the type of port. Can be one of these values: 

           0x0001 - Write
           0x0002 - Read
           0x0004 - Redirected
           0x0008 - Network attached

=head2 Monitors

  Monitors([$server]);

The B<Monitors> function initializes an array of structures with data describing
the monitors for the specified server. B<$server> name of the server on which
the printer drivers should be enumerated.

B<Return keys in table order:>

 {Name}
       Name of the monitor.

 {Environment}
              String specifying the environment in which the monitor
              dynamic-link library (DLL) is designed to run. 

 {DLLName}
          Name of the monitor DLL.

=head2 Processors

  Processors([$server, [$environment]]);

The B<Processors> function enumerates the print processors installed on the
specified server. B<$server> name of the server on which the printer drivers
should be enumerated. B<$environment> specifies the environment (for example,
"Windows NT x86", "Windows NT R4000", "Windows NT Alpha_AXP", or "Windows 4.0").

=head2 Types

  Types([$server, [$processor]]);

The B<Types> function enumerates the data types that a specifed print processor
supports. B<$server> name of the server on which the printer drivers
should be enumerated. Default processor is B<"WinPrint">.

=head1 SEE ALSO

L<Win32::Printer>, Win32 Platform SDK GDI documentation.

=head1 AUTHOR

B<Edgars Binans>

=head1 COPYRIGHT AND LICENSE

B<Win32::Printer, Copyright (C) 2003-2005 Edgars Binans.>

B<THIS LIBRARY IS LICENSED UNDER THE TERMS OF GNU LESSER GENERAL PUBLIC LICENSE
V2.1>

=cut
