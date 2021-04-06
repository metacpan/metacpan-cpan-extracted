########################################################################
#
# Test overloaded conversions of Win32::OLE objects using MS Excel
#
########################################################################
# If you rearrange the tests, please renumber:
# perl -i.bak -pe "++$t if !$t || s/^# \d+\./# $t./" 7_overload.t
########################################################################

use strict;
use Cwd;
use Sys::Hostname;

use Win32::OLE qw(OVERLOAD);

$|=$^W = 1;

open(ME,$0) or die $!;
my $TestCount = grep(/\+\+\$Test/,<ME>);
close(ME);

# 1. Create a new Excel automation server
my ($Excel,$File);
BEGIN {
    $File = cwd . "\\test.xls";
    $File =~ s#\\#/#g, chomp($File = `cygpath -w '$File'`) if $^O eq 'cygwin';
    unless (-f $File) {
	print "1..0 # skip $File doesn't exist! Please run test 3_ole.t first\n";
	exit 0;
    }
    Win32::OLE->Option(Warn => 0);
    $Excel = Win32::OLE->new('Excel.Application', 'Quit');
    Win32::OLE->Option(Warn => 2);
    unless (defined $Excel) {
	my $Msg = Win32::OLE->LastError;
	chomp $Msg;
	$Msg =~ s/\n/\n\# /g;
	print "# $Msg\n";
	print "1..0 # skip Excel.Application not installed\n";
	exit 0;
    }
}

# We only ever get here if Excel is actually installed
my $Test = 0;
print "1..$TestCount\n";
printf "# Excel is %s\n", $Excel;
print "not " unless $Excel eq "Microsoft Excel";
printf "ok %d\n", ++$Test;

# 2. Retrieve a value
my $Book = $Excel->Workbooks->Open($File);
my $Sheet = $Book->Worksheets('My Sheet #1');
my $Cell = $Sheet->Cells(5,5);
my $Value = $Cell->{Value};
printf "# Value is %f\n", $Cell->{Value};
print "not " unless $Cell->{Value} == 4711;
printf "ok %d\n", ++$Test;

# 3. Check if overloading conversion to number/string works
printf "# Value is %f\n", $Cell;
print "not " unless $Cell == 4711;
printf "ok %d\n", ++$Test;
