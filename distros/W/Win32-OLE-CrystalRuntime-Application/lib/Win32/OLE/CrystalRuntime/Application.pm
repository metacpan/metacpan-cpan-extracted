package Win32::OLE::CrystalRuntime::Application;
use base qw{Win32::OLE::CrystalRuntime::Application::Base};
use strict;
use warnings;
use Win32::OLE::CrystalRuntime::Application::Report;
use Win32::OLE;
use DateTime;

our $VERSION='0.12';
our $PACKAGE=__PACKAGE__;

=head1 NAME

Win32::OLE::CrystalRuntime::Application - Perl Interface to the CrystalRuntime.Application OLE Object

=head1 SYNOPSIS

The ASP Version

    Dim oApp, oRpt
    Set oApp = Server.CreateObject("CrystalRuntime.Application")
    Set oRpt = oApp.OpenReport(vFilenameReport, 1)
    oRpt.DisplayProgressDialog = False
    oRpt.MorePrintEngineErrorMessages = False
    oRpt.EnableParameterPrompting = False
    oRpt.DiscardSavedData
    oRpt.ExportOptions.DiskFileName = vFilenameExport
    oRpt.ExportOptions.FormatType = 31                  '31=>PDF
    oRpt.ExportOptions.DestinationType = 1              '1=>filesystem
    oRpt.ExportOptions.PDFExportAllPages = True
    oRpt.Export(False)
    Set oRpt = Nothing
    Set oApp = Nothing

The perl Version

  use Win32::OLE::CrystalRuntime::Application;
  my $application=Win32::OLE::CrystalRuntime::Application->new;
  my $report=$application->report(filename=>$filename);
  $report->setParameters(key1=>$value1, key2=>$value2);
  $report->export(format=>"pdf", filename=>"export.pdf");

=head1 DESCRIPTION

This package allows automation of generating Crystal Reports with Perl.  This package connects to the Crystal Runtime Application OLE object.  You MUST have a license for the Crystal Reports server-side component "Report Designer Control (RDC)" in order for this to work.

                                               Perl API       
                                                  |           
                                        +--------------------+
            Perl API                 +---------------------+ |
               |                  +----------------------+ | |
  +---------------------------+ +----------------------+ | | |
  |                           | |                      | | | |
  |  Perl Application Object  | |  Perl Report Object  | | | |
  |                           | |                      | | | |
  |       "ole" method        | |     "ole" method     | | | |
  |     +==============+      +-+   +==============+   | | | |
  |     |              |      | |   |              |   | | | |
  |     |  Win32::OLE  |      | |   |  Win32::OLE  |   | | | |
  |     |  Application |============|    Report    |   | | | |
  |     |    Object    |      | |   |    Object    |   | | |-+
  |     |              |      | |   |              |   | |-+
  |     +==============+      | |   +==============+   |-+
  +---------------------------+ +----------------------+ 

=head1 USAGE

  use Win32::OLE::CrystalRuntime::Application;
  my $application=Win32::OLE::CrystalRuntime::Application->new(debug=>4);
  my $report=$application->report(filename=>$filename);
  $report->setConnectionProperties("Server"   => "TNSNAME",        #if needed
                                   "User ID"  => "MyAccount",
                                   "Password" => "MyPassword",
                                   "Schema"   => "MySchema");
  $report->setParameters($key1=>$value1, $key2=>$value2);          #if needed
  $report->export(format=>"pdf", filename=>"export.pdf");

=head1 CONSTRUCTOR

=head2 new

  my $application=Win32::OLE::CrystalRuntime::Application->new(
                    ProgramID=>"CrystalRuntime.Application", #default
                  );

  my $application=Win32::OLE::CrystalRuntime::Application->new(
                    ProgramID=>"CrystalRuntime.Application.11", #require version 11
                  );

=head1 METHODS

=head2 ProgramID

Set and returns the Program ID which defaults to "CrystalRuntime.Application".  

  my $string=$application->ProgramID;

You may want to specify the version if you have multiple objects in your environment.

  $application->ProgramID("CrystalRuntime.Application.11");  #Require version 11

=cut

sub ProgramID {
  my $self=shift;
  $self->{'ProgramID'}=shift if @_;
  $self->{'ProgramID'}="CrystalRuntime.Application" unless defined $self->{"ProgramID"};
  return $self->{'ProgramID'};
}

=head2 ole

Set or Returns the OLE Application object.  This object is a Win32::OLE object that is created with a Program ID of "CrystalRuntime.Application"

=cut

sub ole {
  my $self=shift;
  $self->{'ole'}=shift if @_;
  unless (ref($self->{'ole'}) eq "Win32::OLE") {
    printf "%s: %s->%s: Constructing Application OLE Object\r\n", DateTime->now, $PACKAGE, "ole" if $self->debug > 7;
    $self->{'ole'}=Win32::OLE->CreateObject($self->ProgramID);
    die(Win32::OLE->LastError) if Win32::OLE->LastError;
  }
  die("Error: Could not create the Win32::OLE object.")
    unless defined $self->{'ole'};
  return $self->{'ole'};
}

=head2 report

Constructs a report object which is a L<Win32::OLE::CrystalRuntime::Application::Report>.

  my $report=$application->report(filename=>$filename);

=cut

sub report {
  my $self=shift;
  my %data=@_;
  die("Error: Filename is not readable") unless -r $data{"filename"};
  $data{"application"}=$self;
  $data{"debug"}=$self->debug unless defined($data{"debug"});
  printf "%s: %s->%s: Constructing Report Object\r\n", DateTime->now, $PACKAGE, "report" if $self->debug > 7;
  return Win32::OLE::CrystalRuntime::Application::Report->new(%data);
}

=head1 METHODS (OLE Wrappers)

=head2 GetVersion

Returns $application->ole->GetVersion

=cut

sub GetVersion {shift->ole->GetVersion};

=head1 BUGS

=head1 SUPPORT

Please try Business Objects.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  STOP, LLC
  domain=>stopllc,tld=>com,account=>mdavis
  http://www.stopllc.com/

=head1 COPYRIGHT

This program is free software licensed under the...

  The BSD License

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

Crystal Reports XI Technical Reference Guide - http://support.businessobjects.com/documentation/product_guides/boexi/en/crxi_Techref_en.pdf

L<Win32::OLE>, L<Win32::OLE::CrystalRuntime::Application::Report>

=cut

1;
