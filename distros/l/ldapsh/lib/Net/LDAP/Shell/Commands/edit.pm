# edit an entry...

use strict;

use Net::LDAP::Shell::Util qw(debug edit entry2ldif);
use Net::LDAP::Entry;
use Getopt::Long;

use Exporter;
use vars qw($VERSION @ISA);
$VERSION = 1.00;
@ISA = qw(Exporter);

sub update {
	my ($tmpfile,$entry) = @_;

	my %hash;
	open TMP, $tmpfile or die "Could not open $tmpfile: $!\n";
	while (my $line = <TMP>) {
		chomp $line;

		# skip blanks and comments, even though I don't know if it's legal
		$line =~ /^\s*#/ and next;
		$line =~ /^\s*$/ and next;

		my ($attr,$value) = split /: /, $line;

		push @{ $hash{$attr} }, $value;
	}
	close TMP;

	my @oatts = $entry->attributes();
	debug("oatts [@oatts]");

	my $dn = shift @{ $hash{'dn'} };
	if ($dn ne $entry->dn) {
		warn "Object renaming is not supported at this time.\n";
		return 4;
	}
	delete $hash{'dn'};

	foreach my $attr (keys %hash) {
		debug("working on attr $attr");
		unless (grep /$attr/, @oatts) {
			debug("adding $attr");
			$entry->add(
				$attr => $hash{$attr},
			);
			next;
		}
		my @ovals = $entry->get_value($attr);
		my @nvals = @{ $hash{$attr} };
		debug("compare: $attr ovals [@ovals] nvals [@nvals]");

		if (join('',@ovals) ne join('',@nvals)) {
			debug("replacing $attr");
			$entry->replace(
				$attr => $hash{$attr},
			);
			next;
		}
	}

	foreach my $attr (@oatts) {
		unless (grep /$attr/, keys %hash) {
			debug("deleting $attr");
			$entry->delete($attr);
		}
	}
	$entry->dump();
	return $entry->update($CONFIG{'ldap'});
}
# update
#------------------------------------------------------------------------------
sub main {

	my ($entry,$string,$tmpfile,$osum);
	my ($value,$results);

	my ($optresult,@attrs,$usage,$help);

	$usage = "USAGE: edit [--attr <attribute> --attr <attribute>] <LDAP filter>\n";

	$optresult = GetOptions(
		'attr=s'		=> \@attrs,
		'help'		=> \$help,
	);

	if ($help) {
		print
"This command is for editing existing objects.  It accepts
a '--attr' argument, as many times as you want, as a specified
list of attributes to edit.  If no attributes are specified,
all are pulled down.

$usage";
		return 0;
	}

	my $rdn = shift @ARGV or warn $usage and return 1;

	debug("rdn is $rdn");

	unless (@attrs) {
		@attrs = qw(*);
	}

	$results = $CONFIG{'ldap'}->search(
		'base'	=> $CONFIG{'base'},
		'filter'	=> $rdn,
		'scope'	=> 'one',
		'attrs'	=> \@attrs,
	);
	$results->code and warn $results->error, return 2;

	if ($results->all_entries > 1) {
		warn "This command currently not supported on more than one entry.\n";
		warn "Please narrow your search.\n";
		return;
	}

	unless ($results->all_entries) {
		warn "Entry $rdn not found\n";
		return 3;
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
	#system($ENV{'EDITOR'},$tmpfile);
	unless (edit($tmpfile,$osum)) {
		return 0;
	}

	$results = update($tmpfile,$entry);
	while ($results->code()) {
		warn $results->error, "\n";
		print "reedit? ([Y]/n)";
		my $ans = readline STDIN;
		if ($ans =~ /[nN]/) {
			unlink $tmpfile;
			return;
		}
		unless (edit($tmpfile,$osum)) {
			return 0;
		}
		$results = update($tmpfile,$entry);
	}
}

1;
