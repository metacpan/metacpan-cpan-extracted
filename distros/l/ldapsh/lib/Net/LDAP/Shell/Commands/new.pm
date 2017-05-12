# create a new LDAP object

# you can assume the existence of a %CONFIG variable with everything
# you need for ldap connections
#

use strict;

use Net::LDAP::Entry;
use Net::LDAP::Shell::Util qw(debug error edit);
use Getopt::Long;

use vars qw($DEBUG);

use Exporter;
use vars qw($VERSION @ISA);
$VERSION = 2.00;
@ISA = qw(Exporter);

# pull the 'must' or 'may' attributes
sub collect {
	my $type = shift;
	my $schema = shift;

	my @ocs = @_;

	unless ($type eq 'may' or $type eq 'must') {
		warn "Invalid search $type on schema\n";
		return;
	}

	my %hash;

	foreach my $oc (@ocs) {
		my @tmp = $schema->$type($oc);
		map { next unless ref $_; $hash{$_->{'name'}}++ } @tmp;
	}

	return keys %hash;
}

sub create {
	my $tmpfile = shift;

	my %hash;

 	open TMP, $tmpfile or die "Could not open $tmpfile: $!\n";
	while (my $line = <TMP>) {
		chomp $line;

		# skip blanks and comments, even though I don't know if it's legal
		$line =~ /^\s*#/ and next;
		$line =~ /^\s*$/ and next;

		# also skip anything that still has the word REPLACE in it
		$line =~ /REPLACE$/ and next;

		# and anything without a value
		$line =~ /: $/ and next;
		my ($attr,$value) = split /: /, $line;

		push @{ $hash{$attr} }, $value;
	}
	close TMP;

	unless (exists $hash{'dn'}) {
		die "Failed to retrieve DN; exiting.\n";
	}
	my $entry = Net::LDAP::Entry->new();
	$entry->dn(shift @{ $hash{'dn'} });
	delete $hash{'dn'};

	$entry->add(%hash);

	if ($DEBUG) {
		$entry->dump;
	} else {
		return $entry->update($CONFIG{'ldap'});
	}
}

sub main {
	my ($usage,$optresult,$help,$helptext,);

	$usage = "new [--help] <objectclass> <objectclass> ..\n";
	$optresult = GetOptions(
		'help'		=> \$help,
		'debug'		=> \$DEBUG,
	);

	$helptext =
"Create a new LDAP entry.  You can specify which objectclasses
will comprise the entry and <new> will automatically fill
in all of the available attributes.  Optional attributes will
be commented out -- you can uncomment them and fill them in,
or leave them alone and they'll be ignored -- and mandatory
attributes will be uncommented.
";

	unless ($optresult) {
		warn $usage;
		return 1;
	}

	if ($help) {
		print $usage,$helptext;
		return;
	}

	my @ocs = @ARGV;

	my $schema = $CONFIG{'ldap'}->schema();

	my @may = collect('may',$schema,@ocs);
	my @must = collect('must',$schema,@ocs);
	my @parents = parents($schema,@ocs);

	my %base = %CONFIG;

	# okay, by now we know all of the things we need, now we just
	# need to create the tmp file

	my $text = "";
	$text .= "dn: REPLACE,$base{'base'}\n";

	# put in the parent OCs
	map {	$text .= "objectclass: $_\n"; } sort @parents;

	# now set the reqs and options

	# we sort across both at once, both so all atts are sorted but
	# also because given a list of OCs, some may consider an att optional
	# while others consider it mandatory
	my %must;
	map { $must{$_}++ } @must;

	foreach my $attr (sort (@must,@may)) {
		$attr =~ /objectclass/i and next;
		# if anything required it...
		if ($must{$attr}) {
			$text .= "$attr: \n";
		} else {
			$text .= "#$attr: \n";
		}
	}

	# okay, now we have our empty OC

	my ($tmpfile,$osum,$nsum,%hash,$entry);
	$tmpfile = "/tmp/ldapshnew-$$";

	open TMP, ">$tmpfile" or die "Could not open $tmpfile: $!\n";
	print TMP $text;
	close TMP;

	$osum = qx|sum $tmpfile|;
	chomp $osum;

	unless (edit($tmpfile,$osum)) {
		return 0;
	}

	my $results = create($tmpfile);

	while ($results->code()) {
		warn $results->error, "\n";
		print "reedit? ([Y]/n)";
		my $ans = readline STDIN;
		if ($ans =~ /[nN]/) {
			unlink $tmpfile;
			return;
		}
		unless (edit($tmpfile,$osum)) {
			unlink $tmpfile;
			return 0;
		}
		$results = create($tmpfile);
	}
	unlink $tmpfile;
}

# collect a list of all parent objectclasses

sub parents {
	my ($schema,@ocs) = @_;

	my %hash;

	foreach my $oc (@ocs) {
		my @tmp = $schema->superclass($oc);

		map { $hash{$_}++ } @tmp;

		foreach my $oc (@tmp) {
			next if $oc =~ /top/i;
			map { $hash{$_}++ } parents($schema,$oc);
		}
	}

	map { $hash{$_}++ } @ocs;
	
	return keys %hash;
}

1;
