use warnings;
use strict;

use Test::More tests => 3;

BEGIN {
	use_ok "Time::OlsonTZ::Data", qw(
		olson_all_names olson_country_selection
	);
}

my $anames = olson_all_names;
my $sel = olson_country_selection;

is ref($sel), "HASH";

my $failures = 0;
foreach(keys %$sel) {
	/\A[A-Z]{2}\z/ or $failures++;
	my $cnt = $sel->{$_};
	ref($cnt) eq "HASH" or $failures++;
	$cnt->{alpha2_code} eq $_ or $failures++;
	defined($cnt->{olson_name}) or $failures++;
	my $regs = $cnt->{regions};
	ref($regs) eq "HASH" or $failures++;
	scalar(keys %$regs) != 0 or $failures++;
	(scalar(keys %$regs) != 1 xor exists($regs->{""})) or $failures++;
	foreach(keys %$regs) {
		my $reg = $regs->{$_};
		$reg->{olson_description} eq $_ or $failures++;
		exists $anames->{$reg->{timezone_name}} or $failures++;
		exists $reg->{location_coords} or $failures++;
	}
}
is $failures, 0;

1;
