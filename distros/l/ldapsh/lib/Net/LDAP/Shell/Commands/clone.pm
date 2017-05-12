# edit an entry...
use strict;

use Net::LDAP::Shell::Util qw(debug entry2ldif);
use Net::LDAP::Entry;
use Getopt::Long;

use Exporter;
use vars qw($VERSION @ISA);
$VERSION = 1.00;
@ISA = qw(Exporter);

sub main {

	my ($entry,$string,$tmpfile,$nsum,$osum,$line,%hash,$attr,);
	my ($value,@nvalues,@ovalues,$results);
	my (@natts,@oatts,$dn,$help);

	my ($optresult,@attrs,$usage);

	$usage = "USAGE: clone <LDAP filter>\n";

	$optresult = GetOptions(
		'help'		=> \$help,
	);

	if ($help) {
		print
"This command is for copying LDAP objects.  It can be
used to quickly create new objects similar to existing ones.

$usage";
		return 0;
	}

	my $rdn = shift @ARGV or warn $usage and return 1;

	debug("rdn is $rdn");

	$results = $CONFIG{'ldap'}->search(
		'base'	=> $CONFIG{'base'},
		'filter'	=> $rdn,
		'attrs'	=> \@attrs,
	);
	$results->code and warn $results->error, return 2;

	if ($results->all_entries > 1) {
		warn "This command currently not supported on more than one entry.\n";
		warn "Please narrow your search.\n";
		return 3;
	}

	unless ($results->all_entries) {
		warn "Entry $rdn not found\n";
		return 4;
	}

	$entry = $results->pop_entry;

	$tmpfile = "/tmp/edit-$$";

	$string = entry2ldif($entry);

	open TMP, ">$tmpfile" or die "Could not open $tmpfile: $!\n";
	print TMP $string;
	close TMP;

	$osum = qx|sum $tmpfile|;
	chomp $osum;

	$ENV{'EDITOR'} ||= "vi";
	system($ENV{'EDITOR'},$tmpfile);

	$nsum = qx|sum $tmpfile|;
	chomp $nsum;

	if ($osum eq $nsum) {
		warn "Entry did not change\n";
		return;
	}

	open TMP, $tmpfile or die "Could not open $tmpfile: $!\n";
	while ($line = <TMP>) {
		chomp $line;

		# skip blanks and comments, even though I don't know if it's legal
		$line =~ /^\s*#/ and next;
		$line =~ /^\s*$/ and next;

		($attr,$value) = split /: /, $line;

		push @{ $hash{$attr} }, $value;
	}
	close TMP;
	unlink $tmpfile;

	$entry = Net::LDAP::Entry->new();

	$dn = shift @{ $hash{'dn'} };
	debug("dn is $dn");
	$entry->dn($dn);

	delete $hash{'dn'};

	foreach $attr (keys %hash) {
		debug("adding $attr");
		$entry->add(
			$attr => $hash{$attr},
		);
		next;
	}

	$entry->dump();
	$results = $entry->update($CONFIG{'ldap'});
	$results->code and warn $results->error;
}

1;
