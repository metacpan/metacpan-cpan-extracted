use Test::More tests => 8;
use_ok('Tie::NetAddr::IP');

my %HostType;

tie %HostType, Tie::NetAddr::IP;

$HostType{"200.44.0.0/18"} = "Sun";
$HostType{"200.44.64.120/18"} = "Compaq";
$HostType{"0.0.0.0/0"} = "Unknown";
$HostType{"200.44.32.10"} = "SGI";

is($HostType{"10.10.10.10"}, "Unknown");
delete $HostType{"0.0.0.0/0"};
ok(! exists $HostType{"10.10.10.10"}, "unexistence");
ok(! defined $HostType{"10.10.10.10"}, "undefinedness");

$HostType{"161.196.66.0/25"} = "Dell";
delete $HostType{"161.196.66.2"};
is($HostType{"161.196.66.2"}, "Dell");
is($HostType{"200.44.0.0"}, "Sun");
is($HostType{"200.44.64.120"}, "Compaq");
is($HostType{"200.44.32.10"}, "SGI");


