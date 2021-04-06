########################################################################
# If you rearrange the tests, please renumber:
# perl -i.bak -pe "++$t if !$t || s/^# \d+\./# $t./" 5_unicode.t
########################################################################
#
# !!! These tests will not run unless "Unicode::String" is installed !!!
#
########################################################################

use strict;
no warnings "utf8";

use FileHandle;
use Win32::OLE::Variant;

$^W = 1;
STDOUT->autoflush(1);
STDERR->autoflush(1);
Win32::OLE->Option(CP => Win32::OLE::CP_UTF8);

open(ME,$0) or die $!;
my $TestCount = grep(/\+\+\$Test/,<ME>);
close(ME);

eval { require Unicode::String };
if ($@) {
    print "1..0 # skip Unicode::String module not installed\n";
    exit 0;
}

my $Test = 0;
print "1..$TestCount\n";

# 1. Create a simple BSTR and convert to Unicode and back
my $v = Variant(VT_BSTR, '3,1415');
printf "# Type=%s Value=%s\n", $v->Type, $v->Value;
my $u = $v->Unicode;
print "not " unless $u->utf8 eq '3,1415';
printf "ok %d\n", ++$Test;

# 2. Check if we can convert a _big_ unicode character
$v = Variant(VT_BSTR, "\x{263a}");
$u = $v->Unicode;
printf "# v='%s' u='%s'\n", $v->Value, $u->utf8;
print "not " unless "\342\230\272" eq $u->utf8;
printf "ok %d\n", ++$Test;

# 3. Convert Unicode::String back to Variant
$v = Variant(VT_BSTR, $u);
printf "# v='%s' u='%s'\n", $v->Value, $u->utf8;
print "not " unless  "\x{263a}" eq $v->Value;
printf "ok %d\n", ++$Test;
