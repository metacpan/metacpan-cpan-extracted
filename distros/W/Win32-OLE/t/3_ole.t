########################################################################
#
# Test Win32::OLE.pm module using MS Excel
#
########################################################################
# If you rearrange the tests, please renumber:
# perl -i.bak -pe "++$t if !$t || s/^# \d+\./# $t./" 3_ole.t
########################################################################

package Excel;
use strict;
use Win32::OLE;

use strict qw(vars);
use vars qw($AUTOLOAD @ISA $Warn $LastError $CP $LCID $Tie $Variant);
# use BEGIN because the class is already used in BEGIN block later
BEGIN {
    @ISA = qw(Win32::OLE);
    $CP   = Win32::OLE->Option('CP');
    $LCID = Win32::OLE->Option('LCID');
    # This is necessary to get the _NewEnum property access working!
    $Tie  = "Excel::Tie";
    @Excel::Tie::ISA = qw(Win32::OLE::Tie);
    @Excel::Variant::ISA = qw(Win32::OLE::Variant);
}

sub AUTOLOAD {
    my $self = shift;
    $AUTOLOAD = "Win32::OLE::" . substr $AUTOLOAD, rindex($AUTOLOAD, ':')+1;
    my $retval = $self->$AUTOLOAD(@_);
    return $retval if defined($retval) || $AUTOLOAD eq 'DESTROY';
    printf "# $AUTOLOAD returned OLE error 0x%08x\n", $LastError;
    $::Fail = $::Test;
    return;
}


########################################################################

package main;
use strict;
no warnings "utf8";

use Cwd;
use FileHandle;
use Sys::Hostname;

use Win32::OLE qw(CP_ACP CP_OEMCP CP_UTF8 HRESULT in valof with);
use Win32::OLE::NLS qw(:DEFAULT :LANG :SUBLANG :LOCALE);
use Win32::OLE::Variant;

$Excel::Variant = 1;
$Excel::CP = CP_UTF8;

use vars qw($Test $Fail);

$^W = 1;

STDOUT->autoflush(1);
STDERR->autoflush(1);

open(ME,$0) or die $!;
my $TestCount = grep(/\+\+\$Test/,<ME>);
close(ME);

sub stringify {
    my $arg = shift;
    return "<undef>" unless defined $arg;
    if (ref $arg eq 'ARRAY') {
	my $res;
	foreach my $elem (@$arg) {
	    $res .= "," if defined $res;
	    $res .= stringify($elem);
	}
	return "[$res]";
    }
    return "$arg";
}

sub Quit {
  $_[0]->Win32::OLE::Quit;
  print "not " unless ++$Test == $TestCount;
  print "ok $TestCount\n";
}

# 1. Create a new Excel automation server
my $Excel;
BEGIN {
    $Excel::Warn = 0;
    $Excel = Excel->new('Excel.Application', \&Quit);
    $Excel::Warn = 2;
    unless (defined $Excel) {
	my $Msg = Excel->LastError;
	chomp $Msg;
	$Msg =~ s/\n/\n\# /g;
	print "# $Msg\n";
	print "1..0 # skip Excel.Application not installed\n";
	exit 0;
    }
}
# We only ever get here if Excel is actually installed
use Win32::OLE::Const ('Microsoft Excel');

$Test = 0;
print "1..$TestCount\n";
my $File = cwd . "\\test.xls";
if ($^O eq 'cygwin') {
    $File =~ s#\\#/#g;
    chomp($File = `cygpath -w '$File'`);
}
# Excel 2007 doesn't handle forward slashes anymore...
$File =~ s#/#\\#g;
unlink $File if -f $File;
print "# File is '$File'\n";

printf "# Excel is %s\n", $Excel;
my $Type = Win32::OLE->QueryObjectType($Excel);
print "# App object type is $Type\n";
printf "ok %d\n", ++$Test;

# 2. Make sure the CreateObject function works too
my $Obj;
my $Value = Win32::OLE::CreateObject('Excel.Application', $Obj);
print "not " unless $Value && UNIVERSAL::isa($Obj, 'Win32::OLE');
printf "ok %d\n", ++$Test;
$Obj->Quit if defined $Obj;

# 3. Add a workbook (with default number of sheets)
$Excel->{SheetsInNewWorkbook} = 3;
my $Book = $Excel->Workbooks->Add;
$Type = Win32::OLE->QueryObjectType($Book);
print "# Book object type is $Type\n";
print "not " unless defined $Book;
printf "ok %d\n", ++$Test;

# 4. Test if class is inherited by objects created through $Excel
print "not " unless UNIVERSAL::isa($Book,'Excel');
printf "ok %d\n", ++$Test;

# 5. Generate OLE error, should be "croaked" by Win32::OLE
eval { local $Excel::Warn = 3; $Book->Xyzzy(223); };
my $Msg = $@;
chomp $Msg;
$Msg =~ s/\n/\n\# /g;
print "# Died with msg:\n# $Msg\n";
print "not " unless $@;
printf "ok %d\n", ++$Test;

# 6. Generate OLE error, should be trapped by Excel subclass
$Fail = -1;
{ local $Excel::Warn = 0; $Book->Xyzzy(223); };
printf "# Excel::LastError returns (num): 0x%08x\n", Excel->LastError();
$Msg = Excel->LastError();
$Msg =~ s/\n/\n\# /g;
printf "# Excel::LastError returns (str):\n# $Msg\n";
Excel->LastError(0);
printf "# Excel::LastError returns (num): 0x%08x\n", Excel->LastError();
printf "# Excel::LastError returns (str): %s\n", Excel->LastError();
print "not " if $Fail != $Test;
printf "ok %d\n", ++$Test;

# 7. Set 'Warn' option to subroutine reference
$Msg = '';
Excel->Option(Warn => sub {goto Error});
$Book->Plugh(42);
$Msg = "not ";
Error:
printf "${Msg}ok %d\n", ++$Test;
Excel->Option(Warn => 2);

# 8. Get an object for 1st worksheet
my $Sheet = $Book->Worksheets(1);
$Type = Win32::OLE->QueryObjectType($Sheet);
print "# Sheet object type is $Type\n";
print "not " unless defined $Sheet;
printf "ok %d\n", ++$Test;

# 9. Catch "invalid type" error, test if index is correct
{ local $Excel::Warn = 0; $Sheet->Cells(1, $Sheet); };
$Msg = Excel->LastError();
$Msg =~ s/\n/\n\# /g;
printf "# Excel::LastError returns (str):\n# $Msg\n";
print "not " unless $Msg =~ /"Cells" argument 2/;
printf "ok %d\n", ++$Test;

# 10. Test the "with" function
printf("# Tests %d and %d will fail if no default printer has been installed yet\n",
       $Test+1, $Test+2);
with($Sheet->PageSetup, Orientation => xlLandscape, FirstPageNumber => 13);
$Value = $Sheet->PageSetup->FirstPageNumber;
print "# FirstPageNumber is \"$Value\"\n";
print "not " unless $Value == 13;
printf "ok %d\n", ++$Test;

# 11. Test constant value: xlLandscape should be "2"
$Value = $Sheet->PageSetup->Orientation;
print "# Orientation is \"$Value\"\n";
print "not " unless $Value == 2;
printf "ok %d\n", ++$Test;

# 12. Test Win32::OLE::Const->Load method
my $xl = Win32::OLE::Const->Load('Microsoft Excel');
printf "# xlLandscape is \"%s\"\n", $xl->{'xlLandscape'};
print "not " unless $xl->{'xlLandscape'} == 2;
printf "ok %d\n", ++$Test;

# 13. Call a method with a magical scalar as argument
my $Sheets = $Book->Worksheets;
my $Name = $Book->Worksheets($Sheets->{Count})->{Name};
print "# Name is \"$Name\"\n";
print "not " unless $Name;
printf "ok %d\n", ++$Test;

# 14. Set values of some cells and retrieve a value
$Sheet->{Name} = 'My Sheet #1';
foreach my $i (1..10) {
  $Sheet->Cells($i,$i)->{Value} = $i**2;
}
my $Cell = $Sheet->Cells(5,5);
$Type = Win32::OLE->QueryObjectType($Cell);
printf "# Cells (%s) object type is $Type\n", ref($Cell);
$Value = $Cell->{Value};
print "# Value is \"$Value\"\n";
print "not " unless $Cell->{Value} == 25;
printf "ok %d\n", ++$Test;

# 15. Call OLE method with $1 as argument

# This test is commented out because Perl doesn't set POK on $1,
# it seems to be only pPOK, which still gets translated to undef. :(

#Excel->Option(Warn => 0);
#$_ = "The formula is MIN(77,33,55)";
#print "# Expression is \"$1\"\n" if /is (.*)/;
##$Value = $Sheet->Evaluate("MIN(77,33,55)") if /is (.*)/;
#$Value = $Sheet->Evaluate($1) if /is (.*)/;
#Excel->Option(Warn => 2);
#$Value = "" unless defined $Value;
#print "# Value is \"$Value\"\n";
#print "not " unless $Value eq "33";

printf "ok %d\n", ++$Test;

# 16. Test the valof function
my $RefOf = $Cell;
my $ValOf = valof $Cell;
$Cell->{Value} = 27;
print "not " unless $ValOf == 25 && $RefOf->Value == 27;
printf "ok %d\n", ++$Test;

# 17. Assign and retrieve a very long string
$Cell->{Value} = 'a' x 300;
printf "# Value is %s\n", $Cell->Value;
print "not " unless $Cell->Value eq ('a' x 300);
printf "ok %d\n", ++$Test;

# 18. Assign a substr() magical lvalue (doesn't get POK bit set)
$Cell->Dispatch([Win32::OLE::DISPATCH_PROPERTYPUT, 'Value'],
		my $retval, substr('xyz', 0, 1));
printf "# Value is %s\n", $Cell->Value;
print "not " unless $Cell->Value eq 'x';
printf "ok %d\n", ++$Test;

# 19. Try to roundtrip a VT_CY value and see if it stays a Variant
$Cell->{Value} = Variant(VT_CY, 1.25);
$Value = $Cell->{Value};
printf "# Value is %s, ref=%s, type=%d\n", $Value, ref $Value, $Value->Type;
print "not " unless $Cell->Value == 1.25 &&
                    ref($Value) eq "Excel::Variant" &&
                    $Value->Type == VT_CY;
printf "ok %d\n", ++$Test;

# 20. Test 'SetProperty' function
$Cell->SetProperty('Value', 4711);
printf "# Value is %s\n", $Cell->Value;
print "not " unless $Cell->Value == 4711;
printf "ok %d\n", ++$Test;

# 21. The following tests rely on the fact that the font is not yet bold
printf "# Bold: %s\n", $Cell->Style->Font->Bold;
print "not " if $Cell->Style->Font->Bold;
printf "ok %d\n", ++$Test;

# 22. Assignment by DISPATCH_PROPERTYPUTREF shouldn't work
my $Style = $Book->Styles->Add("MyStyle");
$Style->Font->{Bold} = 1;
{ local $Excel::Warn = 0; $Cell->{Style} = $Style }
my $LastError = Excel->LastError;
printf "# Bold: %s\n", $Cell->Style->Font->Bold;
printf "# Excel->LastError is 0x%x\n", $LastError;
print "not " if $LastError != HRESULT(0x80020003) || $Cell->Style->Font->Bold;
printf "ok %d\n", ++$Test;

# 23. But DISPATCH_PROPERTYPUT should be ok
$Cell->LetProperty('Style', $Style);
printf "# Bold: %s\n", $Cell->Style->Font->Bold;
print "not " unless $Cell->Style->Font->Bold;
printf "ok %d\n", ++$Test;

# 24. Set a cell range from an array ref containing an IV, PV and NV
$Sheet->Range("A8:C9")->{Value} = [[undef, 'Camel', "\x{263a}"],[42, 'Perl', 3.1415]];
$Value = $Sheet->Cells(9,2)->Value . $Sheet->Cells(8,2)->Value;
print "# Value is \"$Value\"\n";
print "not " unless $Value eq 'PerlCamel';
printf "ok %d\n", ++$Test;

# 25. Retrieve float value (esp. interesting in foreign locales)
$Value = $Sheet->Cells(9,3)->{Value};
print "# Value is \"$Value\"\n";
print "not " unless $Value == 3.1415;
printf "ok %d\n", ++$Test;

# 26. Retrieve unicode value.
$Value = $Sheet->Cells(8,3)->{Value};
print "# Value is \"$Value\"\n";
print "not " unless $Value eq "\x{263a}";
printf "ok %d\n", ++$Test;

# 27. Make sure the length of the unicode string is correct.
$Value = $Sheet->Cells(8,3)->{Value};
print "# length(Value) is ", length($Value), "\n";
print "not " unless length($Value) == length("\x{263a}");
printf "ok %d\n", ++$Test;

# 28. Use Unicode::String object to assign BSTR value
eval { require Unicode::String };
++$Test;
if ($@) {
    printf "ok %d # skip Unicode::String module not installed\n", $Test;
}
else {
    $Sheet->Cells(1,3)->{Value} = Unicode::String::utf8("\342\230\272");
    $Value = $Sheet->Cells(1,3)->{Value};
    print "# Value is \"$Value\"\n";
    print "not " unless $Value eq "\x{263a}" && length($Value) == 1;
    printf "ok %d\n", $Test;
}

# 29. Retrieve a 0 dimensional range; check array data structure
$Value = $Sheet->Range("B8")->{Value};
printf "# Values are: \"%s\"\n", stringify($Value);
print "not " if ref $Value;
printf "ok %d\n", ++$Test;

# 30. Retrieve a 1 dimensional row range; check array data structure
$Value = $Sheet->Range("B8:C8")->{Value};
printf "# Values are: \"%s\"\n", stringify($Value);
print "not " unless @$Value == 1 && ref $$Value[0];
printf "ok %d\n", ++$Test;

# 31. Retrieve a 1 dimensional column range; check array data structure
$Value = $Sheet->Range("B8:B9")->{Value};
printf "# Values are: \"%s\"\n", stringify($Value);
print "not " unless @$Value == 2 && ref $$Value[0] && ref $$Value[1];
printf "ok %d\n", ++$Test;

# 32. Retrieve a 2 dimensional range; check array data structure
$Value = $Sheet->Range("B8:C9")->{Value};
printf "# Values are: \"%s\"\n", stringify($Value);
print "not " unless @$Value == 2 && ref $$Value[0] && ref $$Value[1];
printf "ok %d\n", ++$Test;

# 33. Check contents of 2 dimensional array
$Value = $$Value[0][0] . $$Value[1][0] . $$Value[1][1];
print "# Value is \"$Value\"\n";
print "not " unless $Value eq 'CamelPerl3.1415';
printf "ok %d\n", ++$Test;

# 34. Set a cell formula and retrieve calculated value
$Sheet->Cells(3,1)->{Formula} = '=PI()';
$Value = $Sheet->Cells(3,1)->{Value};
print "# Value is \"$Value\"\n";
print "not " unless abs($Value-3.141592) < 0.00001;
printf "ok %d\n", ++$Test;

# 35. Add single worksheet and check that worksheet count is incremented
my $Count = $Sheets->{Count};
$Book->Worksheets->Add;
$Value = $Sheets->{Count};
print "# Count is \"$Count\" and Value is \"$Value\"\n";
print "not " unless $Value == $Count+1;
printf "ok %d\n", ++$Test;

# 36. Add 2 more sheets, optional arguments are omitted
$Count = $Sheets->{Count};
$Book->Worksheets->Add(undef,undef,2);
$Value = $Sheets->{Count};
print "# Count is \"$Count\" and Value is \"$Value\"\n";
print "not " unless $Value == $Count+2;
printf "ok %d\n", ++$Test;

# 37. Add 3 more sheets before sheet 2 using a named argument
$Count = $Sheets->{Count};
$Book->Worksheets(2)->{Name} = 'XYZZY';
$Sheets->Add($Book->Worksheets(2), {Count => 3});
$Value = $Sheets->{Count};
print "# Count is \"$Count\" and Value is \"$Value\"\n";
print "not " unless $Value == $Count+3;
printf "ok %d\n", ++$Test;

# 38. Previous sheet 2 should now be sheet 5
$Value = $Book->Worksheets(5)->{Name};
print "# Value is \"$Value\"\n";
print "not " unless $Value eq 'XYZZY';
printf "ok %d\n", ++$Test;

# 39. Add 2 more sheets at the end using 2 named arguments
$Count = $Sheets->{Count};
# Following line doesn't work with Excel 7 (Seems like an Excel bug?)
# $Sheets->Add({Count => 2, After => $Book->Worksheets($Sheets->{Count})});
$Sheets->Add({Count => 2, After => $Book->Worksheets($Sheets->{Count}-1)});
print "not " unless $Sheets->{Count} == $Count+2;
printf "ok %d\n", ++$Test;

# 40. Number of objects in an enumeration must match its "Count" property
my @Sheets = in $Sheets;
printf "# \$Sheets->{Count} is %d\n", $Sheets->{Count};
printf "# scalar(\@Sheets) is %d\n", scalar(@Sheets);
foreach my $Sheet (@Sheets) {
    printf "# Sheet->{Name} is \"%s\"\n", $Sheet->{Name};
}
print "not " unless $Sheets->{Count} == @Sheets;
printf "ok %d\n", ++$Test;
undef @Sheets;

# 41. Enumerate all application properties using the C<keys> function
my @Properties = keys %$Excel;
printf "# Number of Excel application properties: %d\n", scalar(@Properties);
$Value = grep /^(Parent|Xyzzy|Name)$/, @Properties;
print "# Value is \"$Value\"\n";
print "not " unless $Value == 2;
printf "ok %d\n", ++$Test;
undef @Properties;

# 42. Translate character from ANSI -> OEM
++$Test;
my $oemcp = GetLocaleInfo(GetSystemDefaultLCID(), LOCALE_IDEFAULTCODEPAGE);
if ($oemcp == 437 || $oemcp == 850) {
    my ($Version) = $Excel->{Version} =~ /([0-9.]+)/;
    print "# Excel version is $Version\n";

    my $LCID = MAKELCID(MAKELANGID(LANG_ENGLISH, SUBLANG_NEUTRAL));
    $LCID = MAKELCID(MAKELANGID(LANG_NEUTRAL, SUBLANG_NEUTRAL)) if $Version >= 8;
    $Excel::LCID = $LCID;

    $Cell = $Book->Worksheets('My Sheet #1')->Cells(1,5);
    $Cell->{Formula} = '=CHAR(163)';
    $Excel::CP = CP_ACP;
    my $ANSI = valof $Cell;
    $Excel::CP = CP_OEMCP;
    my $OEM = valof $Cell;
    print "# ANSI(cp1252) -> OEM(cp437/cp850): 163 -> 156\n";
    printf "# ANSI is \"$ANSI\" (%d) and OEM is \"$OEM\" (%d)\n", ord($ANSI), ord($OEM);
    print "not " unless ord($ANSI) == 163 && ord($OEM) == 156;
    printf "ok %d\n", $Test;
}
else {
    printf "ok %d # skip OEM codepage $oemcp is neither 437 nor 850\n", $Test;
}

# 43. Save workbook to file
print "not " unless $Book->SaveAs($File);
printf "ok %d\n", ++$Test;

# 44. Check if output file exists.
print "not " unless -f $File;
printf "ok %d\n", ++$Test;

# 45. Access the same file object through a moniker.
$Obj = Win32::OLE->GetObject($File);
for ($Count=0 ; $Count < 5 ; ++$Count) {
    my $Type = Win32::OLE->QueryObjectType($Obj);
    print "# Object type is \"$Type\"\n";
    last if $Type =~ /Workbook/;
    $Obj = $Obj->{Parent};
}
$Value = 2.7172;
eval { $Value = $Obj->Worksheets('My Sheet #1')->Range('A3')->{Value}; };
print "# Value is \"$Value\"\n";
print "not " unless abs($Value-3.141592) < 0.00001;
printf "ok %d\n", ++$Test;


# 46. Get return value as Win32::OLE::Variant object
$Cell = $Obj->Worksheets('My Sheet #1')->Range('B9');
my $Variant = Win32::OLE::Variant->new(VT_EMPTY);
$Cell->Dispatch('Value', $Variant);
printf "# Variant is (%s,%s)\n", $Variant->Type, $Variant->Value;
print "not " unless $Variant->Type == VT_BSTR && $Variant->Value eq 'Perl';
printf "ok %d\n", ++$Test;

# 47. Use clsid string to start OLE server
undef $Value;
eval {
    require Win32::Registry;
    Win32::Registry->import(qw(RegOpenKeyEx KEY_READ));
    use vars qw($HKEY_CLASSES_ROOT);
    # Use Win32::Registry internals to open registry key in readonly mode
    RegOpenKeyEx($HKEY_CLASSES_ROOT->{handle}, 'Excel.Application\CLSID',
		 undef, KEY_READ(), my $HKey);
    $HKey = Win32::Registry::_new($HKey);
    $HKey->QueryValue('', my $CLSID);
    $HKey->Close;
    print "# Excel CLSID is $CLSID\n";
    $Obj = Win32::OLE->new($CLSID);
    $Value = (Win32::OLE->QueryObjectType($Obj))[0];
    $Obj->Quit if $Value eq 'Excel';
};
++$Test;
if ($@) {
    printf "ok %d # skip Registry problem $@\n", $Test;
}
else {
    print "# Object application is $Value\n";
    print "not " unless $Value eq 'Excel';
    printf "ok %d\n", $Test;
}

# 48. Use DCOM syntax to start server (on local machine though)
#     This might fail (on Win95/NT3.5 if DCOM support is not installed.
$Obj = Win32::OLE->new([hostname, 'Excel.Application'], 'Quit');
$Value = (Win32::OLE->QueryObjectType($Obj))[0];
print "# Object application is $Value\n";
print "not " unless $Value eq 'Excel';
printf "ok %d\n", ++$Test;

# 49. Find $Excel object via EnumAllObjects()
my $Found = 0;
$Count = Win32::OLE->EnumAllObjects(sub {
    my $Object = shift;
    my $Class = Win32::OLE->QueryObjectType($Object);
    $Class = "" unless defined $Class;
    printf "# Object=%s Class=%s\n", $Object, $Class;
    $Found = 1 if $Object == $Excel;
});
print "# Count=$Count Found=$Found\n";
print "not " unless $Found;
printf "ok %d\n", ++$Test;

# 50. _NewEnum should normally be non-browseable
my $Exists = grep /^_NewEnum$/, keys %{$Excel->Worksheets};
print "# Exists=$Exists\n";
print "not " if $Exists;
printf "ok %d\n", ++$Test;

# 51. make _NewEnum visible
Excel->Option(_NewEnum => 1);
$Exists = grep /^_NewEnum$/, keys %{$Excel->Worksheets};
print "# Exists=$Exists\n";
print "not " unless $Exists;
printf "ok %d\n", ++$Test;

# 52. _NewEnum available as a method
@Sheets = @{$Excel->Worksheets->_NewEnum};
print "# $_->{Name}\n" foreach @Sheets;
print "not " unless @Sheets == 11 && grep $_->Name eq "My Sheet #1", @Sheets;
printf "ok %d\n", ++$Test;

# 53. _NewEnum available as a property
@Sheets = @{$Excel->Worksheets->{_NewEnum}};
print "not " unless @Sheets == 11 && grep $_->Name eq "My Sheet #1", @Sheets;
printf "ok %d\n", ++$Test;

# 54. Win32::OLE proxies are non-unique by default
my $Application = $Excel->Application;
my $Parent = $Excel->Parent;
printf "# Application=%d Parent=%d\n", $Application, $Parent;
print "not " if $Application == $Parent;
printf "ok %d\n", ++$Test;

# 55. Parent and Application property should now return the same object
Excel->Option(_Unique => 1);
$Application = $Excel->Application;
$Parent = $Excel->Parent;
printf "# Application=%d Parent=%d\n", $Application, $Parent;
print "not " unless $Application == $Parent;
printf "ok %d\n", ++$Test;

# 56. Determine Dispatch ID of "Parent"
my $dispid = $Excel->GetIDsOfNames("Parent");
print "# DispID=$dispid\n";
print "not " unless $dispid == 150;
printf "ok %d\n", ++$Test;

# 57. Dispatch using numeric ID instead of method/property name
$Parent = $Excel->Invoke($dispid);
printf "# Application=%d Parent=%d\n", $Application, $Parent;
print "not " unless $Application == $Parent;
printf "ok %d\n", ++$Test;

# 58. Terminate server instance ("ok $Test\n" printed by Excel destructor)
exit;
