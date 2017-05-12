use strict;

use Net::LDAP::Shell::Util qw(debug entry2ldif error);
use Net::LDAP::Shell qw(shellSearch);
use Getopt::Long;

use Exporter;
use vars qw($VERSION @ISA);
$VERSION = 1.00;
@ISA = qw(Exporter);

sub main {
	my ($usage,$results,$entry,@attrs,$optresult,$help,$helptext);

	$usage = "cat [-attr <attribute> ..] <ldap entry>\n";
	$optresult = GetOptions(
		'attr=s'		=> \@attrs,
		'help'		=> \$help,
	);

	$helptext =
"Cats the contents of an entry, in LDIF, to the screen.  Arguments
are treated as LDAP filters.
";

	unless ($optresult) {
		debug("bad args; exiting");
		warn $usage;
		return 1;
	}

	unless (@ARGV) {
		debug("no argv; exiting");
		warn $usage;
		return;
	}

	if ($help) {
		warn $usage,$helptext;
		return;
	}

	my %args;

	if (@attrs) {
		$args{'attrs'} = \@attrs;
	}
	$args{'filter'} = shift @ARGV;
	my @entries = shellSearch(%args) or 
		warn ("$args{'filter'}: not found.\n"), return;

	foreach $entry (@entries) {
		print entry2ldif($entry);
		print "\n";
	}
}

1;
