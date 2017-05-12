#!/usr/bin/perl

=head1 NAME

Win32-OLE-CrystalRuntime-Application-Parameters.pl - CrystalRuntime-Application Parameter Example

=cut

use strict;
use warnings;

my $string=shift || "foo";
my $number=shift || "3.1415926";  #always pass as string and convert in report

use Win32::OLE::CrystalRuntime::Application;
my $application=Win32::OLE::CrystalRuntime::Application->new;
my $file;
foreach (qw{hello.rpt t/hello.rpt ../t/hello.rpt}) {
  $file=$_;
  last if -r;
}
my $report=$application->report(filename=>$file);
$report->setParameters(FILTER_STRING=>$string, FILTER_NUMBER=>$number);

$report->ole->{"PrintDate"}="12/01/2009";
$report->ole->{"PrintTime"}="01:02:03";  #Does not work!!!

$report->export(filename=>"hello.pdf");
$report->export(format=>"xls", filename=>"hello.xls");
