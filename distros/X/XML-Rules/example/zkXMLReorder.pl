use strict;
use warnings;
no warnings 'uninitialized';

use XML::Rules;

my %written;
my %depends;
my $parser = XML::Rules->new(
	style => 'filter',
	ident => "\t",
	stripspaces => 2,
	rules => {
		_default => 'as array',
		'Group' => 'content array',
		'name,comments,members' => 'as is',
		record => sub {
#use Data::Dumper;
#print Dumper($_[1]);
			my @I_depend;
			if (exists $_[1]->{members} and exists $_[1]->{members}{Group}) {
				@I_depend = grep !exists $written{$_}, @{$_[1]->{members}{Group}};
			}
			if (@I_depend) {
				$_[1]->{':I_depend'} = {map {$_ => 1} @I_depend};
				foreach (@I_depend) {
					push @{$depends{$_}}, $_[1]
				}
				return;
			} else {
				my $name = $_[1]->{name}{_content};
				$written{$name} = 1;
				my @to_write = $_[1];
				if (exists $depends{$name}) {
					push @to_write, find_dependent($name);
				}
				return 'record' => \@to_write;
			}
		}
	}
);

sub find_dependent {
	my $name = shift;
	my @to_write;
	foreach my $parent (@{$depends{$name}}) {
		delete $parent->{':I_depend'}{$name};
		if (! %{$parent->{':I_depend'}}) { # if it doesn't depend on anything more, write it after this one
			push @to_write, $parent;
			push @to_write, find_dependent($parent->{name}{_content});
		}
	}
	delete $depends{$name};
	return @to_write;
}

$parser->filterfile('c:\temp\Groups.xml');

use Data::Dumper;
if (%depends) {
    print STDERR "\nUnsatisfied dependencies!\n";
    foreach my $missing (keys %depends) {
        print STDERR "Missing group '$missing' is a member of:\n";
		print STDERR "BUT IT WAS WRITTEN!!\n" if (exists $written{$missing})
        foreach my $failed (@{$depends{$missing}}) {
            print STDERR Dumper($failed);
            print STDERR "  $failed->{':name'}{_content}\n";
        }
    }
}

# ' "
__DATA__
<SystemXchange version="1.0">

	<summary>
		<tool version="2.8 build: [070207]">Enterprise Migration Tool</tool>
		<source></source>
		<comments> </comments>
		<timestamp>May 30, 2008 @ 10:00:00 CDT</timestamp>
	</summary>



<!--Begin Group Records-->

	<records type="group" operation="insert">

	<record>
		<name>GOLF</name>
		<comments> </comments>
		<departments>
			<department>Default</department>
		</departments>
		<members>
			<Group>ECHO</Group>
			<Group>BETA</Group>
			<Group>DELTA</Group>
			<Group>FOXTROT</Group>
			<Destination>bj1234</Destination>
		</members>
		<ta_properties>
			<FullName> </FullName>
		</ta_properties>
	</record>

	<record>
		<name>ECHO</name>
		<comments> </comments>
		<departments>
			<department>Default</department>
		</departments>
		<members>
			<Group>CHARLIE</Group>
			<Group>DELTA</Group>
			<Destination>cn1234</Destination>
			<Destination>mc1234</Destination>
		</members>
		<ta_properties>
			<FullName> </FullName>
		</ta_properties>
	</record>

	<record>
		<name>CHARLIE</name>
		<comments> </comments>
		<departments>
			<department>Default</department>
		</departments>
		<members>
			<Group>ALPHA</Group>
			<Group>DELTA</Group>
			<Destination>zt1234</Destination>
			<Destination>rx1234</Destination>
		</members>
		<ta_properties>
			<FullName> </FullName>
		</ta_properties>
	</record>

	<record>
		<name>BETA</name>
		<comments> </comments>
		<departments>
			<department>Default</department>
		</departments>
		<members>
			<Destination>bp1234</Destination>
			<Destination>cm1234</Destination>
			<Group>FOXTROT</Group>
			<Group>CHARLIE</Group>
		</members>
		<ta_properties>
			<FullName> </FullName>
		</ta_properties>
	</record>

	<record>
		<name>FOXTROT</name>
		<comments> </comments>
		<departments>
			<department>Default</department>
		</departments>
		<members>
			<Group>ALPHA</Group>
			<Destination>cn1234</Destination>
			<Destination>sc1234</Destination>
			<Destination>sp1234</Destination>
		</members>
		<ta_properties>
			<FullName> </FullName>
		</ta_properties>
	</record>

	<record>
		<name>DELTA</name>
		<comments> </comments>
		<departments>
			<department>Default</department>
		</departments>
		<members>
			<Group>ALPHA</Group>
			<Group>FOXTROT</Group>
		</members>
		<ta_properties>
			<FullName> </FullName>
		</ta_properties>
	</record>

	<record>
		<name>ALPHA</name>
		<comments> </comments>
		<departments>
			<department>Default</department>
		</departments>
		<members>
			<Destination>sm1234</Destination>
		</members>
		<ta_properties>
			<FullName> </FullName>
		</ta_properties>
	</record>


</records>

</SystemXchange>
