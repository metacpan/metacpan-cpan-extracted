#!/usr/bin/perl

=head1 NAME

Win32-OLE-CrystalRuntime-Application-Information.pl - CrystalRuntime-Application Extract Report Information Example

=cut

use strict;
use warnings;
use DateTime;
use Data::Dumper;
use Win32::OLE::CrystalRuntime::Application;

my $application=Win32::OLE::CrystalRuntime::Application->new;
my $file;
foreach (qw{hello.rpt t/hello.rpt ../t/hello.rpt}) {
  $file=$_;
  last if -r;
}

printf qq{%s: File "%s"\n}, DateTime->now, $file;

my $report=$application->report(filename=>$file);

printf qq{%s: Report Title: %s\n}, DateTime->now, $report->title;
printf qq{%s: Report Author: %s\n}, DateTime->now, $report->author;
printf qq{%s: Report Comments: %s\n}, DateTime->now, $report->comments;
printf qq{%s: Report Subject: %s\n}, DateTime->now, $report->subject;

printf qq{%s: Report Sections\n}, DateTime->now;

foreach my $section ($report->sections) {
  printf qq{%s:   Name: %s (%s)\n}, DateTime->now, $section->Name, $section->Number;
}

printf qq{%s: Report Objects\n}, DateTime->now;
foreach my $object ($report->objects) {
  printf qq{%s:   Name: %s, Kind: %s\n}, DateTime->now, $object->Name, $object->Kind;
}
