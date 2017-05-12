
BEGIN {
    our @Loc = (
		"Lab, First Floor",
		"Datacenter, Second Floor",
		"Remote location",
		"God knows where",
		);
    our @Cases = (
		  ["10.0.10.1", 0],
		  ["10.0.20.15", 1],
		  ["10.0.30.17", 2],
		  ["10.10.0.1", 3],
		  );
};

use Data::Dumper;
use Test::More tests => @Cases + 1;

use_ok('Tie::NetAddr::IP');

my %WhereIs;

tie %WhereIs, Tie::NetAddr::IP;

$WhereIs{"10.0.10.0/24"} = $Loc[0];
$WhereIs{"10.0.20.0/24"} = $Loc[1];
$WhereIs{"10.0.30.0/27"} = $Loc[2];
$WhereIs{"0.0.0.0/0"} = $Loc[3];

#print Data::Dumper->Dump([(tied %WhereIs)]);

foreach $host (@Cases) 
{
#    diag("Testing case $host->[0], $host->[1]\n");
    is($WhereIs{$host->[0]}, $Loc[$host->[1]]);
}

untie %WhereIs;

