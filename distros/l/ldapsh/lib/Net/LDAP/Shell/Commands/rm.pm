# this is a stub package, used to create new commands

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

	my ($usage,$results,$entry,@attrs,$optresult,$help,$helptext,$force);

	$usage = "rm [--help] [--force] <filter> <filter> ..\n";
	$optresult = GetOptions(
		'help'		=> \$help,
		'force'		=> \$force,
	);

	$helptext =
"Removes LDAP entries.  Always confirms removal unless --force is
in effect.
";

	unless ($optresult) {
		warn $usage;
		return 1;
	}

	if ($help) {
		print $usage,$helptext;
		return;
	}

	unless (@ARGV) {
		warn $usage;
		return 2;
	}

	my %args;

	foreach (my $filter = shift @ARGV) {
		debug("filter is $filter");
		$args{'filter'} = $filter;
		my @entries = shellSearch(%args) or do {
			warn "$filter: not found\n";
			next;
		};

		foreach my $entry (@entries) {
			debug("entries are @entries");
			unless ($force) {
				print "Delete ", $entry->dn(), "? (y/[n]) ";
				my $answer = <STDIN>;
				unless ($answer =~ /y/i) {
					next;
				}
			}

			$entry->changetype('delete');
			my $result = $entry->update($CONFIG{'ldap'});
			$result->code and warn $result->error();
		}
	}
}

1;
