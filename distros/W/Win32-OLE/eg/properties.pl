# Print out all  Microsoft Excel application properties

use strict;
use Win32::OLE;
$Win32::OLE::Warn = 3;

my $Excel = Win32::OLE->new('Excel.Application', 'Quit');
# Add a workbook to get some more property values defined
$Excel->Workbooks->Add;
print "Excel application properties:\n";
foreach my $Key (sort keys %$Excel) {
    my $Value;
    eval {$Value = $Excel->{$Key} };
    $Value = "***Exception***" if $@;
    $Value = "<undef>" unless defined $Value;
    $Value = '['.Win32::OLE->QueryObjectType($Value).']' 
      if UNIVERSAL::isa($Value,'Win32::OLE');
    $Value = '('.join(',',@$Value).')' if ref $Value eq 'ARRAY';
    printf "%s %s %s\n", $Key, '.' x (25-length($Key)), $Value;
}
