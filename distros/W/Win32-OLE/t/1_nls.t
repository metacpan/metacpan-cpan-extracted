########################################################################
#
# Test of Win32::OLE::NLS
#
########################################################################
# If you rearrange the tests, please renumber:
# perl -i.bak -pe "++$t if !$t || s/^# \d+\./# $t./" 1_nls.t
########################################################################

use strict;
use FileHandle;
use Win32::OLE::NLS qw(/./);

$^W = 1;
STDOUT->autoflush(1);
STDERR->autoflush(1);

open(ME,$0) or die $!;
my $TestCount = grep(/\+\+\$Test/,<ME>);
close(ME);

my $Test = 0;
print "1..$TestCount\n";

# 1. Create English locale identifier
my $langID = MAKELANGID(LANG_ENGLISH, SUBLANG_NEUTRAL);
my $lcid = MAKELCID($langID);
print "not " unless $lcid == 9;
printf "ok %d\n", ++$Test;

# 2. Query "English name of language"
print "not " unless GetLocaleInfo($lcid,LOCALE_SENGLANGUAGE) eq "English";
printf "ok %d\n", ++$Test;

