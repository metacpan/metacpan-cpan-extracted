package Net::LDAP::Shell::Schema;

use Exporter;
use Net::LDAP::Shell::Util qw(serverType);
use Net::LDAP::Shell qw(shellSearch);
use vars qw(@EXPORT @ISA);

#require "/home/luke/bin/test";

@ISA = qw(Exporter);
@EXPORT = qw(
	getSchema
	recurse_oc
);

####################################################################################
# getSchema
#
# pulls the schema from the ldap server
#
sub getSchema
{
	my (@ocs,%base,@entries,$dse,$type,);

	use vars qw($schema);

	if ($schema) { return $schema; }

	$base{'ldap'} = shift;
	$base{'filter'} = 'objectclass=*';

	$type = serverType($base{'ldap'}) or return;

	for ($type)
	{
		/iplanet/ and do
		{
			$base{'base'} = 'cn=schema';
			next;
		};
		/openldap/ and do
		{
			$base{'base'} = 'cn=subschema';
			next;
		};
		warn "Server type '$type' not understood.\n";
		return;
	}

	$base{'attrs'} = [qw(objectclasses attributetypes)];

	@entries = shellSearch(%base) or
		warn error("Could not find schema entry") and
		return;

	$schema = shift @entries;

	return $schema;
}
# getSchema
####################################################################################

####################################################################################
# lineSplit
#
# split an attributeTypes or objectclasses definition into its pieces
# sucky sucky
sub lineSplit
{
	use Parse::RecDescent;
	my $line = shift;

	use vars qw($PARSER $GRAMMAR);

	$GRAMMAR ||= q[
line: /\( / oid item(s) /\)\z/
{
	my %hash;
	$hash{'oid'} = $item{'oid'};
	foreach my $top (@{ $item{'item'} })
	{
		if (ref $top eq 'ARRAY')
		{
			push @{ $hash{'detail'} }, @{ $top };
		}
		elsif (ref $top eq 'HASH')
		{
			foreach my $var (keys %$top)
			{
				$hash{$var} = $top->{$var};
			}
		}
		else
		{
			push @{ $hash{'detail'} }, $top;
		}
	}

	\%hash;
}
oid: /^[.0-9]+/ | /^\S+-oid/ | /^\S+-OID/
item: withval | word
word: /^([-A-Z]+)/ { my $var = $1; $var =~ tr/A-Z/a-z/; $var; }
withval: word overvalue
{
	my %hash;
	$hash{ $item{'word'} } = $item{'overvalue'};
	\%hash;
}
overvalue: /^\(/ value(s) /\)/ { $item{'value'}; }
	| /^\(/ valuedollars(s) /\)/ { $item{'valuedollars'}; }
	| value { [ $item{'value'} ]; }
valuedollars: value /\$?/ { $item{'value'}; }
value: /'([^']+)'/ { $1; } | /\S*[a-z0-9]\S*/
];

	$PARSER ||= new Parse::RecDescent ($GRAMMAR);

	unless (defined $PARSER)
	{
		die "Bad grammar!\n";
	}

	return $PARSER->line($line);
}
# lineSplit
####################################################################################

####################################################################################
# schema_to_hash
#
# this routine looks up the schema for an ldap database, and splits it
# out entirely and converts it into one big hash
sub schema_to_hash
{
	$| = 1;

	my ($attr,$oc,$schema,$ref,);

	use vars qw(%main);

	if (%main) { return \%main; } # return cached copy if possible

	$schema = shift;

	foreach $attr ($schema->get_value('attributeTypes'))
	{
		$ref = lineSplit($attr,);
		unless (defined $ref)
		{
			die "Failed to match '$attr'\n";
		}
		if (ref $ref->{'name'})
		{
			foreach (@{ $ref->{'name'} })
			{
				$main{'at'}->{ $_ } = $ref;
			}
		}
		else
		{
			$main{'at'}->{ $ref->{'name'} } = $ref;
		}
	}

	foreach $oc ($schema->get_value('objectClasses'))
	{
		$ref = lineSplit($oc,);
		unless (defined $ref)
		{
			die "Failed to match '$oc'\n";
		}
		unless (exists $ref->{'name'})
		{
			print "no name: $oc\n";
			map { print "$_ => $ref->{$_}\n"; } keys %$ref;
			next;
		}
		if (ref $ref->{'name'})
		{
			foreach (@{ $ref->{'name'} })
			{
				$main{'oc'}->{ $_ } = $ref;
			}
		}
		else
		{
			$main{'oc'}->{ $ref->{'name'} } = $ref;
		}

		#$main{'oc'}->{ $$ref{'name'} } = $ref;
	}

=begin comment
	foreach $top (keys %main)
	{
		print "$top\n";
		foreach $name (sort keys %{ $main{$top} })
		{
			print "\t$name\n\t\t";
			print join " ", keys %{ $main{$top}->{$name} };
			print "\n";
		}
	}
=cut

	return \%main;
}
# schema_to_hash
####################################################################################

####################################################################################
# recurse_oc
#
# this routine takes the hash from schema_to_hash and recursively prints
# out of the required attributes for a specific OC
sub recurse_oc
{
	my $schema = shift;
	my $oc = shift;
	my $ref = schema_to_hash($schema);
	my %oc = %{ $ref->{'oc'} };
	my (@names,$name,$sup,$var,@tmp);

	#foreach (sort keys %oc)
	#{
	#	print "$_ => ", join " ", keys %{ $oc{$_} };
	#	print "\n";
	#}
	#print "person => ", join(" ", keys %{ $oc{'person'} }), "\n";

	#unless (@names = grep /$oc/i, keys %{ $hash{'oc'} })
	unless (@names = grep /$oc/i, keys %oc)
	{
		warn "No matching objectclass\n";
		return '0';
	}

	#print "@names\n";

	foreach (@names)
	{
		if ($oc =~ /^$_$/i)
		{
			$name = $_;
		}
	}

	if (! $name) 
	{
		warn "Could not exactly match objectclass\n";
		return '0';
	}

	my %hash = %{ $oc{$name} };

	unless ($sup = shift @{ $hash{'sup'} })
	{
		warn "Could not retrieve superior\n";
		return '0';
	}

	delete $hash{'sup'};

	while (1)
	{
		if (! $oc{$sup})
		{
			warn "Superior '$sup' does not exist\n";
			last;
		}
		push @{ $hash{'sup'} }, $sup;

		#foreach $var (keys %{ $oc{$sup} })
		foreach $var (qw(must may))
		{
			unless (exists $oc{$sup}->{$var}) { next; }

			if ($oc{$sup}->{$var} =~ /ARRAY/)
			{
				@tmp = @{ $oc{$sup}->{$var} };
				foreach my $tmp (@tmp)
				{
					unless (grep /^$tmp$/, @{ $hash{$var} })
					{
						push @{ $hash{$var} }, $tmp;
					}
				}
			}
			else
			{
				print "$oc{$sup}->{$var}\n";
			}
		}

		if ($sup eq 'top')
		{
			last;
		}
		unless ($sup = shift @{ $oc{$sup}->{'sup'} })
		{
			warn "Could not retrieve superior of $sup\n";
			return '0';
		}
	}

	return %hash;
}
# recurse_oc
####################################################################################

1;
