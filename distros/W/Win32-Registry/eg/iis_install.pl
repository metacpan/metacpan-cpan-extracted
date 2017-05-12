#perl -w
#
# Install this Perl as MS IIS and MS Personal Web server script processor.
#
# Written by Jeff Urlwin <jurlwin@access.digex.net>
#

use Win32::Registry;
use Getopt::Long;
use Config;

# use strict;
# can't seem to get Win32::Registry to work correctly with strict.
# it doesn't like $HKEY_LOCAL_MACHINE, below...
#

$::opt_o = 0;		# override current value of .pl in IIS...
GetOptions(qw(o!)) or die "Invalid arguments";

$perlexe = $Config{binexp} . "\\perl.exe";

print "Your configuration (lib\Config.pm) is invalid. ",
    "binexp is not set to where your perl.exe is located\n"
    unless -f $perlexe;

my $ScriptMapKey;
my $regkey
    = "SYSTEM\\CurrentControlSet\\Services\\W3SVC\\Parameters\\Script Map";

$HKEY_LOCAL_MACHINE->Open($regkey, $ScriptMapKey)
    or die "You do not have IIS or PWS installed!\n$!\n";

my %values = ();

if ($ScriptMapKey->GetValues(\%values)) {
    print "You currently have the following mappings.\n";
    foreach (sort keys (%values)) {
	print "Key: $_, Value = $values{$_}[2]\n";
    }
    print "\n";

    print "Perl is installed as a valid script for IIS/PWS\n"
	if $values{".pl"};

    if ($opt_o or !$values{".pl"}) {

	print "Setting perl as the script handler for .pl files ($perlexe).\n";

	if (!$ScriptMapKey->SetValueEx('.pl', NULL, REG_SZ, "$perlexe %s %s")) {
	    print "update of .pl value failed: $!\n",
		"Do you have permission to do this?\n";
	}
	print "$!\n";
    }
}
else {
    print "no keys?  Something's wrong...\n";
}

$ScriptMapKey->Close();
