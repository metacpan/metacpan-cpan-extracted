#!/usr/bin/perl
#################
# genLinkStatus.pl
#     This is a sample script to show how status information about a given link
#     should be output. It simply randomly selects a state based on the
#     type of status being checked.
#
#     The first paramter will always exist and will be the type of status being
#     looked up: 'admin' or 'oper'
#
#     A real script might consult an SNMP MA or consult the router via the CLI
#
#     The script should output something like:
#
#     timestamp,[state]
#################

my $type = shift;

my @oper_states = (
	"up",
	"down",
	"degraded",
);

my @admin_states = (
	"normaloperation",
	"maintenance",
	"troubleshooting",
	"underrepair",
);

my $state;

if ($type eq "admin") {
	my $n = int(rand($#admin_states + 1));
	$state = $admin_states[$n];
} elsif ($type eq "oper") {
	my $n = int(rand($#oper_states + 1));
	$state = $oper_states[$n];
} else {
	$state = "unknown";
}

$msg = time() . "," . $state;
print $msg;
