########################################################################
#
# Test of the OLE.pm compatibility module using MS Excel
#
########################################################################
# If you rearrange the tests, please renumber:
# perl -i.bak -pe "++$t if !$t || s/^# \d+\./# $t./" 4_compat.t
########################################################################

use strict;
use FileHandle;
use OLE;

$^W = 1;
STDOUT->autoflush(1);
STDERR->autoflush(1);

open(ME,$0) or die $!;
my $TestCount = grep(/\+\+\$Test/,<ME>);
close(ME);

my $Test = 0;

# 1. Create Excel object using CreateObject syntax
my $xl = CreateObject OLE "Excel.Application";
unless (defined $xl) {
    print "1..0 # skip Excel.Application not installed\n";
    exit 0;
}
print "1..$TestCount\n";

print "# Excel is \"$xl\"\n";
my $bk = $xl->Workbooks->Add;
# This also checks if overloading was turned off again
# Otherwise value of $bk is "" which is FALSE
print "# Value is \"$bk\"\n";
print "not " unless $bk;
printf "ok %d\n", ++$Test;

# 2. "Unnamed" Item method
my $name = $xl->Worksheets(1)->{Name};
my $sheet = $xl->Worksheets->{$name};
print "not " unless UNIVERSAL::isa($sheet, 'Win32::OLE');
printf "ok %d\n", ++$Test;

# 3. Enumerate collection using C<keys %$object> syntax
my @sheets = keys %{$xl->Worksheets};
print "not " unless UNIVERSAL::isa($sheets[0], 'Win32::OLE');
printf "ok %d\n", ++$Test;

# 4. Create VARIANT
my $ovR8 = new OLE::Variant(OLE::VT_R8, '3');
$xl->Range("a2")->{Value} = $ovR8;
print "not " unless $xl->Range("a2")->{Value} == 3;
printf "ok %d\n", ++$Test;

# 5. Quit Excel
$bk->{Saved} = 1;
$xl->Quit;
undef $xl;
printf "ok %d\n", ++$Test;
