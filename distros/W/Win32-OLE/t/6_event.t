########################################################################
#
# Test Win32::OLE Event support using MS Excel
#
########################################################################
# If you rearrange the tests, please renumber:
# perl -i.bak -pe "++$t if !$t || s/^# \d+\./# $t./" 6_event.t
########################################################################

use strict;
use Win32::OLE qw(EVENTS);

use Cwd;

$|=$^W = 1;

open(ME,$0) or die $!;
my $TestCount = grep(/\+\+\$Test/,<ME>);
close(ME);

# 1. Create a new Excel automation server
my ($Excel,$File);
BEGIN {
    $File = cwd . "\\test.xls";
    $File =~ s#\\#/#g, chomp($File = `cygpath -w '$File'`) if $^O eq 'cygwin';
    chomp($File = `cygpath -w '$File'`) if $^O eq 'cygwin';
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
printf "ok %d\n", ++$Test;

# 2. Connect generic Event handler function to Application object
my %Events;
sub Event {
    my ($Obj,$Event) = @_;
    ++$Events{$Event};
    print "# Event triggered: '$Event'\n";
}
Win32::OLE->WithEvents($Excel, \&Event, 'AppEvents');
my $Book = $Excel->Workbooks->Open($File);
print "not " unless $Events{WorkbookOpen};
printf "ok %d\n", ++$Test;

# 3. Connect Event package to Workbook object

# disconnect Application Events
Win32::OLE->WithEvents($Excel);
undef %Events;

my $MayClose;
package Workbook;
sub BeforeClose {
    my ($self,$Cancel) = @_;
    $Cancel->Put(1) unless $MayClose;
    print "# BeforeClose: Cancel is now ", $Cancel->Value, "\n";
}

package main;
Win32::OLE->WithEvents($Book, 'Workbook', 'WorkbookEvents');
printf "# Workbookcount: %d\n", $Excel->Workbooks->Count;
# try to close workbook. This should *not* succeed!
$Book->Close;
my $Count = $Excel->Workbooks->Count;
printf "# Workbookcount: $Count\n";
print "not " unless $Count == 1;
printf "ok %d\n", ++$Test;

# 4. There shouldn't have been any Application events
print "not " if scalar keys %Events;
printf "ok %d\n", ++$Test;

# 5. This time BeforeClose shall *not* cancel the action
$MayClose = 1;
$Book->Close;
$Count = $Excel->Workbooks->Count;
printf "# Workbookcount: $Count\n";
print "not " unless $Count == 0;
printf "ok %d\n", ++$Test;

# 6. Test the Forwarder object
my $forward = Win32::OLE->Forward(sub {$MayClose = shift});
$forward->Invoke(undef, 42);
print "# MayClose is $MayClose\n";
print "not " unless $MayClose == 42;
printf "ok %d\n", ++$Test;
