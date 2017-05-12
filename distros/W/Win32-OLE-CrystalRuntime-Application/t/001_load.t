# -*- perl -*-

use Test::More tests => 67;

use_ok( 'Win32::OLE::CrystalRuntime::Application::Base' );
my $base=Win32::OLE::CrystalRuntime::Application::Base->new(foo=>"bar");
isa_ok ($base, 'Win32::OLE::CrystalRuntime::Application::Base');
is($base->{"foo"}, "bar", "initialize");

SKIP: {
  eval {require Win32::OLE};
  skip qq{Win32::OLE not available.}, 64 if $@;

  ok(1, "Win32::OLE Loaded");
  use_ok( 'Win32::OLE::CrystalRuntime::Application' );
  my $application=Win32::OLE::CrystalRuntime::Application->new;
  isa_ok ($application, 'Win32::OLE::CrystalRuntime::Application');

  use_ok( 'Win32::OLE::CrystalRuntime::Application::Report' );
  my $report=Win32::OLE::CrystalRuntime::Application::Report->new;
  isa_ok ($report, 'Win32::OLE::CrystalRuntime::Application::Report');

  my $obj=Win32::OLE->CreateObject(qq{CrystalRuntime.Application});
  skip qq{CrystalRuntime.Application not available.}, 59
    if Win32::OLE->LastError;

  ok(1, "Program ID: CrystalRuntime.Application Found");
  undef $obj;
  is($application->{"ole"}, undef, 'ole');
  isa_ok($application->ole, 'Win32::OLE'); #Lazy Load

  my $file="hello.rpt";
  my $filename=$file;
  foreach my $path (qw{.. t .} ) {
    $filename="$path/$file";
    last if -r $filename;
  }
  skip qq{Cannot read "$file".}, 56 unless -r $filename;
  ok(-r $filename, "Found $filename");
  $report=$application->report(filename=>$filename);
  isa_ok($report, 'Win32::OLE::CrystalRuntime::Application::Report');
  isa_ok($report->application, 'Win32::OLE::CrystalRuntime::Application');
  isa_ok($report->application->ole, 'Win32::OLE');
  is($report->{"ole"}, undef, 'Win32::OLE');
  isa_ok($report->ole, 'Win32::OLE'); #Lazy load

  is($report->author, "Hello World Author", "filename");
  is($report->comments, "Hello World Comments", "filename");
  is($report->subject, "Hello World Subject", "filename");
  is($report->template, "Hello World Template", "filename");
  is($report->title, "Hello World Title", "filename");
  is($report->keywords, "Hello World Keywords", "filename");
  my @table=$report->tables;
  is(scalar(@table), 0, "tables");
  my $table=$report->tables;
  isa_ok($table, "ARRAY", "tables");
  my @section=$report->sections;
  is(scalar(@section), 5, "sections");
  my $section=$report->sections;
  isa_ok($section, "ARRAY", "sections");
  isa_ok($section->[0], "Win32::OLE");
  isa_ok($section->[1], "Win32::OLE");
  isa_ok($section->[2], "Win32::OLE");
  isa_ok($section->[3], "Win32::OLE");
  isa_ok($section->[4], "Win32::OLE");
  is($section->[0]->{"Name"}, "ReportHeaderSection1", "ReportHeaderSection1");
  is($section->[1]->{"Name"}, "PageHeaderSection1", "PageHeaderSection1");
  is($section->[2]->{"Name"}, "DetailSection1", "DetailSection1");
  is($section->[3]->{"Name"}, "ReportFooterSection1", "ReportFooterSection1");
  is($section->[4]->{"Name"}, "PageFooterSection1", "PageFooterSection1");
  is($section->[0]->{"Number"}, "0", "ReportHeaderSection1");
  is($section->[1]->{"Number"}, "1", "PageHeaderSection1");
  is($section->[2]->{"Number"}, "2", "DetailSection1");
  is($section->[3]->{"Number"}, "3", "ReportFooterSection1");
  is($section->[4]->{"Number"}, "4", "PageFooterSection1");
  is($section->[0]->{"Width"}, "11520", "ReportHeaderSection1");
  is($section->[1]->{"Width"}, "11520", "PageHeaderSection1");
  is($section->[2]->{"Width"}, "11520", "DetailSection1");
  is($section->[3]->{"Width"}, "11520", "ReportFooterSection1");
  is($section->[4]->{"Width"}, "11520", "PageFooterSection1");
  my @object=$report->objects;
  is(scalar(@object), 8, "objects");
  my $object=$report->objects;
  isa_ok($object, "ARRAY", "objects");
  is($object->[0]->{"Name"}, "ReportHeader_PrintDate", "PrintDate");
  is($object->[0]->{"Kind"}, "1", "PrintDate");
  is($object->[1]->{"Name"}, "PrintTime1", "PrintTime");
  is($object->[1]->{"Kind"}, "1", "PrintTime");
  is($object->[2]->{"Name"}, "PageHeader_Label_Number", "Label Number");
  is($object->[2]->{"Kind"}, "2", "Label Number");
  is($object->[3]->{"Name"}, "PageHeader_Label_String", "Label String");
  is($object->[3]->{"Kind"}, "2", "Label String");
  is($object->[4]->{"Name"}, "Details_Field_Number", "Field Number");
  is($object->[4]->{"Kind"}, "1", "Field Number");
  is($object->[5]->{"Name"}, "Details_Field_String", "Field String");
  is($object->[5]->{"Kind"}, "1", "Field String");
  is($object->[6]->{"Name"}, "ReportFooter_Label", "Footer");
  is($object->[6]->{"Kind"}, "2", "Footer");
  is($object->[7]->{"Name"}, "PageFooter_PageNumber", "PageNumber");
  is($object->[7]->{"Kind"}, "1", "PageNumber");
  my @subreport=$report->subreports;
  is(scalar(@subreport), 0, "subreports");
  my $subreport=$report->subreports;
  isa_ok($subreport, "ARRAY", "subreports");
}
