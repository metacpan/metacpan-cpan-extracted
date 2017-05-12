#!/usr/bin/perl -w

use DateTime;
use WebService::OCTranspo;

my $stop  = shift or die q{stop number};
my $route = shift or die q{route number};
my $now  = DateTime->now->set_time_zone('America/New_York');

my $oc = WebService::OCTranspo->new({debug => 0});

my $s  = $oc->schedule_for_stop({
	stop_id  => $stop,
	route_id => $route,
	date     => $now,
});

print "Next $s->{route_number} - $s->{route_name}\n";
print "  departing $s->{stop_name} ($s->{stop_number})\n";
foreach my $timestr ( @{ $s->{times} } ) {
	my ($hh,$mm) = $timestr =~ m/^(\d+):(\d+)/;
	my $then = DateTime->now
		->set_hour($hh)
		->set_minute($mm);
	if( $then > $now ) {
		print "$timestr\n";
	}
}

print join("\n", map { "$_ => $s->{notes}{$_}" } keys %{ $s->{notes} } ),
	"\n";
