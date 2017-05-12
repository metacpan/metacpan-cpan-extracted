# search for a filter

# you can assume the existence of a %CONFIG variable with everything
# you need for ldap connections
#

use strict;

use Net::LDAP::Shell::Util qw(debug error);
use Net::LDAP::Shell qw(shellSearch);
use Getopt::Long;

use Exporter;
use vars qw($VERSION @ISA);
$VERSION = 1.00;
@ISA = qw(Exporter);

sub main {

	my ($usage,$results,$entry,@attrs,$optresult,$help,$helptext,$scope,$base,$attrs,$long);

	$usage = "search [--help] [--scope <sub|base|one>] [--base <base dn>]
				[--attrs <attr,attr,attr,...>] <filter>\n";
	$optresult = GetOptions(
		'help'		=> \$help,
		'scope=s'	=> \$scope,
		'base=s'	=> \$base,
		'attrs=s'	=> \$attrs,
		'long'		=> \$long,
	);

	$helptext =
"Search for entries.

-a --attrs <attr,attr,...>
	A comma separated-list of attributes to return.  Defaults to all normal
	attributes.

-b --base <base dn>
	The entry from which to start searching.  Defaults to the current node.

-l --long
	Print the full entry, rather than just the dn.

-s --scope <sub|base|one>
	The search scope.  Defaults to 'sub'.

";

	unless ($optresult and @ARGV) {
		warn $usage;
		return 1;
	}

	if ($help) {
		print $usage,$helptext;
		return;
	}

	my %args;

	$args{'filter'} = shift @ARGV;

	if ($attrs) {
		$args{'attrs'} = [split /,/, $attrs];
	}

	if ($base) {
		$args{'base'} = $base;
	}

	if ($scope) {
		$args{'scope'} = $scope;
	} else {
		$args{'scope'} = 2;
	}

	foreach my $entry (shellSearch(%args)) {
		if ($long) {
			print "dn: ";
		}
		print $entry->dn, "\n";

		unless ($long) {
			next;
		}
		foreach my $attr ($entry->attributes) {
			foreach my $val ($entry->get_value($attr)) {
				print "$attr: $val\n";
			}
		}

		print "\n";
	}
}

1;
