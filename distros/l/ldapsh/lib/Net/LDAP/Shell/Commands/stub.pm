# this is a stub package, used to create new commands

# you can assume the existence of a %CONFIG variable with everything
# you need for ldap connections
#

use Net::LDAP::Shell::Util qw(debug error);
use Net::LDAP::Shell qw(shellSearch);
use Getopt::Long;

use Exporter;
use vars qw($VERSION @ISA);
$VERSION = 1.00;
@ISA = qw(Exporter);

sub main {

	my ($usage,$results,$entry,@attrs,$optresult,$help,$helptext);

	$usage = "stub [--help]\n";
	$optresult = GetOptions(
		'help'		=> \$help,
	);

	$helptext =
"Help on the stub file.  Right.\n";

	unless ($optresult) {
		warn $usage;
		return 1;
	}

	unless ($optresult) {
		print $usage,$helptext;
		return;
	}
}

1;
