use strict;

use Net::LDAP::Shell::Util qw(debug error);
use Net::LDAP::Shell qw(shellSearch);
use Getopt::Long;

use Exporter;
use vars qw($VERSION @ISA);
$VERSION = 1.00;
@ISA = qw(Exporter);

sub main {
	my (%config,$optresult,$results,$long,$directory,$entry,$dn,$printformat,);
	my ($length,$usage,$help,$helptext);

	$printformat = "%-13s %-19s %-13s %-19s %-4s %-s\n";
	$length = $ENV{'COLUMNS'} || 72;

	$usage = "ls [--help] [--long] [ldap object]\n";
	$optresult = GetOptions(
		'long'		=> \$long,
		'help'		=> \$help,
		#'directory=s'	=> \$directory,
	);

	$helptext =
"The good-old-ls command.  Performs a listing, either on the current
node (sets the filter to 'objectclass=*') or on a specified node.  In
this case, it will set its filter to whatever is on the command line.
";

	unless ($optresult) { warn $usage;
		return 1;
	}

	if ($help) {
		print $usage,$helptext;
		return 0;
	}

	my %args;

	# return only the operational attributes
	# use cat if you want the entry itself
	$args{'attrs'} = [ 
		qw(createTimestamp creatorsName modifyTimestamp 
			modifierssName numsubordinates)
	];

	my @entries;

	if (@ARGV) {
		debug("ls: argv is @ARGV");
		foreach my $filter (@ARGV) {
			debug("ls: working on $filter");
			if ($filter =~ /^(.+),([^,]+)$/) {
				debug("ls: path is deep $filter");
				# notice the use of the global base
				$args{'base'} = "$1,$CONFIG{'base'}";
				$args{'filter'} = $2;
			} else {
				debug("ls: path is shallow $filter");
				$args{'filter'} = $filter;
			}

			debug("ls: filter is $args{'filter'}");
			my @tmp = shellSearch(%args) or do {
				warn("$args{'filter'}: not found.\n"), return;
			};
			push @entries, @tmp;
		}
	}
	else
	{
		$args{'filter'} = '(objectclass=*)';
		@entries = shellSearch(%args) or do {
			warn("$args{'filter'}: not found.\n"), return;
		}
	}
	debug("ls: filter is $args{'filter'}");

	if ($long) {
		#printf "%-15s %-17s %-15s %-17s %-6d %-s\n",
		printf $printformat,
			"Creator","Created","Modifier","Modified","Sub","Name";
		print '-' x $length, "\n";
	}

	#my @entries = shellSearch(%CONFIG) or do
	#{
	#	if (@ARGV)
	#	{
	#		warn("$CONFIG{'filter'}: not found.\n"), return;
	#	}
	#};
	foreach $entry (@entries) {
		$dn = $entry->dn();
		$dn =~ s/,.+$//;

		if ($long) {
			use Date::Manip;

			my ($created,$creator,$modified,$modifier,$children);
			$created = $entry->get_value('createTimestamp') || 0;
			$creator = $entry->get_value('creatorsName') || '-';
			$modified = $entry->get_value('modifyTimestamp') || 0;
			$modifier = $entry->get_value('modifierssName') || '-';
			$children = $entry->get_value('numsubordinates') || '-';

			foreach ($modified,$created) {
				$_ = UnixDate($_,'%m/%d/%Y %H:%M:%S');
			}

			foreach ($creator,$modifier) {
				$_ =~ s/,.+$//;
			}

			printf $printformat,
				$creator,$created,$modifier,$modified,$children,$dn;
		} else {
			print "$dn\n";
		}
	}
}

1;
