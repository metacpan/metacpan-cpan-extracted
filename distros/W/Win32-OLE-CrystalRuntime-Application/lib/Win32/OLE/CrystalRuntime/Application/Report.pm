package Win32::OLE::CrystalRuntime::Application::Report;
use base qw{Win32::OLE::CrystalRuntime::Application::Base};
use Win32::OLE::CrystalRuntime::Application::Constants qw{:CRExportFormatType crEDTDiskFile crSubreportObject crOpenReportByTempCopy};
use strict;
use warnings;
use Win32::OLE;
use Win32::OLE::Variant qw{VT_BOOL};
use constant True => Win32::OLE::Variant->new(VT_BOOL, 1);
use constant False=> Win32::OLE::Variant->new(VT_BOOL, 0);
use DateTime;

our $VERSION='0.12';

=head1 NAME

Win32::OLE::CrystalRuntime::Application::Report - Perl Interface to the Crystal Report OLE Object

=head1 SYNOPSIS

  use Win32::OLE::CrystalRuntime::Application;
  my $application=Win32::OLE::CrystalRuntime::Application->new;
  my $report=$application->report(filename=>$filename);
  $report->export(format=>"pdf", filename=>"export.pdf");

=head1 DESCRIPTION

This package is a wrapper around the OLE object for a Crystal Report.

=head1 USAGE

=head1 CONSTRUCTOR

You must construct this object from a L<Win32::OLE::CrystalRuntime::Application> object as the ole object is constructed at the same time and is generated from the application->ole object.

  use Win32::OLE::CrystalRuntime::Application;
  my $application=Win32::OLE::CrystalRuntime::Application->new;
  my $report=$application->report(filename=>$filename);


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

=head1 METHODS

=head2 filename

Returns the name of the report filename. This value is read only after object construction.

  my $filename=$report->filename;

Set on construction

  my $report=Win32::OLE::CrystalRuntime::Application::Report->new(
               filename=>$filename,
             );

=cut

sub filename {
  my $self=shift;
  $self->{'filename'}=shift if @_;
  return $self->{'filename'};
}

=head2 ole

Returns the OLE report object.  This object is the Win32::OLE object that was constructed during initialization from the $application->report() method.

=cut

sub ole {
  my $self=shift;
  unless (defined $self->{"ole"}) {
    if (-r $self->filename) {
      printf qq{%s: Constructing Report OLE Object with file "%s"\r\n}, DateTime->now, $self->filename if $self->debug > 7;

      $self->{"ole"}=$self->application->ole->OpenReport($self->filename, crOpenReportByTempCopy);
      die(Win32::OLE->LastError) if Win32::OLE->LastError;
      die("Error: Cannot create OLE report object") unless ref($self->ole) eq "Win32::OLE";

      $self->{"ole"}->DiscardSavedData();
      die(Win32::OLE->LastError) if Win32::OLE->LastError;

      $self->{"ole"}->{'DisplayProgressDialog'} = False;
      die(Win32::OLE->LastError) if Win32::OLE->LastError;

      $self->{"ole"}->{'MorePrintEngineErrorMessages'} = False;
      die(Win32::OLE->LastError) if Win32::OLE->LastError;

      $self->{"ole"}->{'EnableParameterPrompting'} = False;
      die(Win32::OLE->LastError) if Win32::OLE->LastError;
    } else {
      die(sprintf(qq{Error: Unable to read file "%s".}, $self->filename));
    }
  }
  return $self->{'ole'};
}

=head2 application

Returns the application object.

  my $application=$report->application;

Set on construction in the $application->report method.

  my $report=Win32::OLE::CrystalRuntime::Application::Report->new(
               application=>$application
             );

=cut

sub application {shift->{"application"}};

=head2 setConnectionProperties

Sets report ConnectionProperties correctly in the correct order.

  $report->setConnectionProperties("Server"   => "TNSNAME",
                                   "User ID"  => "login",
                                   "Password" => "password");


Sets report ConnectionProperties correctly in the correct order and set Schema for tables.

  $report->setConnectionProperties("Server"   => "TNSNAME",
                                   "User ID"  => "login",
                                   "Password" => "password",
                                   "Schema"   => "schematxt");

Tables where you do not want to reset the schema alias them with a "_" (e.g. 'SELECT 1 FROM SYS.DUAL "_DUAL"').

Current Limitations: Oracle support for crdb_oracle.dll only
Current Limitations: SubReports are only searched one level deep; not recursive.

=cut

sub setConnectionProperties {
  my $self=shift;
  my %data=@_;
  printf "%s: Setting Report Connection Properties\r\n", DateTime->now, if $self->debug > 5;

  my @table=$self->tables;  
  die(Win32::OLE->LastError) if Win32::OLE->LastError;

  #Add tables from the subreports in each section (FB 2415)
  foreach ($self->subreports) {
    die(Win32::OLE->LastError) if Win32::OLE->LastError;
    my $subreport=$_->OpenSubreport;  #ISA Win32::OLE object
    die(Win32::OLE->LastError) if Win32::OLE->LastError;
    printf "%s: Subreport: %s\r\n", DateTime->now, $subreport->ReportTitle if $self->debug > 6;
    die(Win32::OLE->LastError) if Win32::OLE->LastError;
    push @table, $self->list_collection($subreport->Database->Tables);
    die(Win32::OLE->LastError) if Win32::OLE->LastError;
  }
  
  foreach my $table (@table) {
    printf "%s: Table: %s, Alias: %s, DLL: %s\r\n", 
             DateTime->now, $table->Location, $table->Name, $table->DllName if $self->debug > 6;
    die(Win32::OLE->LastError) if Win32::OLE->LastError;
    if ($table->DllName eq "crdb_oracle.dll") {
      die(Win32::OLE->LastError) if Win32::OLE->LastError;
      $table->ConnectionProperties("Server")->{'Value'} = $data{"Server"};          #order is VERY important
      die(Win32::OLE->LastError) if Win32::OLE->LastError;
      $table->ConnectionProperties("User ID")->{'Value'} = $data{"User ID"};
      die(Win32::OLE->LastError) if Win32::OLE->LastError;
      $table->ConnectionProperties("Password")->{'Value'} = $data{"Password"};
      die(Win32::OLE->LastError) if Win32::OLE->LastError;
      if (defined $data{"Schema"}) {
        unless ($table->Name=~m/^Command/ or $table->Name=~m/^_/) {
          $table->{'Location'} = sprintf("%s.%s", $data{"Schema"}, $table->Location);
          die(Win32::OLE->LastError) if Win32::OLE->LastError;
        }
      }
   #} elsif ($table->DllName eq "crdb_whatever.dll") { #Add other drivers here but we currently only use Oracle!
    } else {
      printf qq{%s: Warning: Expected report to be developed against a known database driver like Crystal Reports Oracle Driver (crdb_oracle.dll).  However, I found: "%s".  I will not attempt to change database source on table "%s".\r\n}, DateTime->now, $table->DllName, $table->Name;
    }
  }
  return $self;
}

=head2 setParameters

Sets the report parameters.

  $report->setParameters($key1=>$value1, $key2=>$value2, ...);  #Always pass values as strings and convert in report
  $report->setParameters(%hash);

=cut

sub setParameters {
  my $self=shift;
  my $hash={@_};
  my $count=$self->ole->ParameterFields->Count;
  die(Win32::OLE->LastError) if Win32::OLE->LastError;
  printf qq{%s: Parameter Count: %s\r\n}, DateTime->now, $count if $self->debug > 6;
  foreach my $index (1 .. $count) {
    my $key=$self->ole->ParameterFields->Item($index)->ParameterFieldName;
    die(Win32::OLE->LastError) if Win32::OLE->LastError;
    if (defined $hash->{$key}) {
      printf qq{%s: Setting Parameter: "%s" => "%s"\r\n}, DateTime->now, $key, $hash->{$key} if $self->debug > 5;
      $self->ole->ParameterFields->Item($index)->AddCurrentValue($hash->{$key});
      die(Win32::OLE->LastError) if Win32::OLE->LastError;
    } else {
      warn(sprintf(qq{%s: Warning: Report Parameter "%s" is not defined.\r\n}, DateTime->now, $key));
    }
  }
}

=head2 export

Saves the report in the specified format to the specified filename.

  $report->export(filename=>"report.pdf");  #default format is pdf
  $report->export(format=>"pdf", filename=>"report.pdf");
  $report->export(formatid=>31, filename=>"report.pdf"); #pass format id directly

=cut

sub export {
  my $self=shift;
  my $opt={@_};
  my $formatid=$opt->{'formatid'} ||
                 $self->FormatID->{$opt->{'format'}||'pdf'};
  die("Error: export method requires a valid format.") unless $formatid;
  die("Error: export method requires a filename.") unless $opt->{'filename'};

  $self->ole->ExportOptions->{'DestinationType'} = crEDTDiskFile();         #1=>filesystem
  die(Win32::OLE->LastError) if Win32::OLE->LastError;

  $self->ole->ExportOptions->{'FormatType'} = $formatid;
  die(Win32::OLE->LastError) if Win32::OLE->LastError;

  $self->ole->ExportOptions->{'CharStringDelimiter'} = q{"};
  die(Win32::OLE->LastError) if Win32::OLE->LastError;

  $self->ole->ExportOptions->{'CharFieldDelimiter'} = q{,};
  die(Win32::OLE->LastError) if Win32::OLE->LastError;

  $self->ole->ExportOptions->{'ExcelPageBreaks'} = False;
  die(Win32::OLE->LastError) if Win32::OLE->LastError;

  $self->ole->ExportOptions->{'ExcelShowGridLines'} = True;
  die(Win32::OLE->LastError) if Win32::OLE->LastError;

  $self->ole->ExportOptions->{'DiskFileName'} = $opt->{'filename'};
  die(Win32::OLE->LastError) if Win32::OLE->LastError;

  $self->ole->ExportOptions->{'HTMLFileName'} = $opt->{'filename'};
  die(Win32::OLE->LastError) if Win32::OLE->LastError;

  $self->ole->ExportOptions->{'XMLFileName'} = $opt->{'filename'};
  die(Win32::OLE->LastError) if Win32::OLE->LastError;

  $self->ole->ExportOptions->{'PDFExportAllPages'} = True;
  die(Win32::OLE->LastError) if Win32::OLE->LastError;

  $self->ole->Export(False);
  die(Win32::OLE->LastError) if Win32::OLE->LastError;

  return $self;
}

=head2 FormatID

Returns a hash of common format extensions and CRExportFormatType IDs.  Other formats are supported with export(formatid=>$id)

  my $hash=$report->FormatID;           #{pdf=>31, xls=>36};
  my @orderedlist=$report->FormatID;    #(pdf=>31, xls=>36, ...)
  my $id=$report->FormatID->{"pdf"};    #$ i.e. 31

=cut

sub FormatID {
  my $self=shift;
  #Changed csv from 5 to 7 (v7.1) to crEFTCharSeparatedValues (v8.1)
  my @data=(
              pdf  => crEFTPortableDocFormat(),
              xls  => crEFTExcel97(),
              doc  => crEFTWordForWindows(),
              csv  => crEFTCharSeparatedValues(),
              rpt  => crEFTCrystalReport(),
              rtf  => crEFTExactRichText(),
              htm  => crEFTHTML32Standard(),
              html => crEFTHTML40(),
              txt  => crEFTPaginatedText(),
              tsv  => crEFTTabSeparatedValues(),
              xml  => crEFTXML(),
             );
  return wantarray ? @data : {@data};
}

=head1 PROPERTIES (OLE Wrappers)

=head2 author

String. Gets the report author.

=cut

sub author {shift->ole->{"ReportAuthor"}};

=head2 comments

String. Gets report comments.

=cut

sub comments {shift->ole->{"ReportComments"}};

=head2 subject

String. Gets the report subject.

=cut

sub subject {shift->ole->{"ReportSubject"}};

=head2 template

String. Gets the report template.

=cut

sub template {shift->ole->{"ReportTemplate"}};

=head2 title

String. Gets the report title.

=cut

sub title {shift->ole->{"ReportTitle"}};

=head2 keywords

String. Gets the keywords in the report.

=cut

sub keywords {shift->ole->{"KeywordsInReport"}};

=head2 groups

Long. Gets the number of groups in the report.

=cut

sub groups {shift->ole->{"NumberOfGroup"}};

=head2 sql

String. Gets SQL query string.

=cut

sub sql {shift->ole->{"SQLQueryString"}};

=head2 tables

Returns a list of all tables in the report.  

  my $list=$report->tables; #[]
  my @list=$report->tables; #()

=cut

sub tables {
  my $self=shift;
  return $self->list_collection($self->ole->Database->Tables);
}

=head2 sections

Returns a list of all sections in the report.

  my $list=$report->sections; #[]
  my @list=$report->sections; #()

=cut

sub sections {
  my $self=shift;
  return $self->list_collection($self->ole->Sections);
}

=head2 objects

Returns a list of all objects in all sections of the report.

  my $list=$report->objects; #[]
  my @list=$report->objects; #()

Returns a list of all objects of type CRObjectKind in all sections of the report.

  my $list=$report->objects(type=>5); #[] #crSubreportObject
  my @list=$report->objects(type=>1); #() #crFieldObject

=cut

sub objects {
  my $self=shift;
  my %data=@_;
  my @list=map {$self->list_collection($_->ReportObjects)} $self->sections;
  if (defined $data{"type"}) {
    @list=grep {$_->Kind == $data{"type"}} @list;
  }
  return wantarray ? @list : \@list;
}

=head2 subreports

Returns all OLE subreports in the report

Note: This is currently only one level deep and not recursive!!!

=cut

sub subreports {shift->objects(type=>crSubreportObject())};

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

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Win32::OLE::CrystalRuntime::Application>, L<Win32::OLE::CrystalRuntime::Application::Base>, L<Win32::OLE>, L<Win32::OLE::Variant>

=cut

1;
