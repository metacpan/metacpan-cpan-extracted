#!/usr/bin/perl

=head1 NAME

Win32-OLE-CrystalRuntime-Application-Example.pl - CrystalRuntime-Application Simple Export Example

=cut

use strict;
use warnings;
use Win32::OLE::CrystalRuntime::Application;
my $application=Win32::OLE::CrystalRuntime::Application->new;
my $file;
foreach (qw{hello.rpt t/hello.rpt ../t/hello.rpt}) {
  $file=$_;
  last if -r;
}
my $report=$application->report(filename=>$file);
$report->export(filename=>"hello.pdf");
