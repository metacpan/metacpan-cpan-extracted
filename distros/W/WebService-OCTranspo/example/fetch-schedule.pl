#!/usr/bin/perl -w

use DateTime;
use WebService::OCTranspo;

my $stop  = shift or die q{stop number};
my $route = shift or die q{route number};
my $date  = DateTime->now()->subtract(days=>1);

my $oc = WebService::OCTranspo->new();

my $s  = $oc->schedule_for_stop({
	stop_id  => $stop,
	route_id => $route,
	date     => $date,
});

print 
	join("\n", @{ $s->{times} } ),
	"\n",
	join("\n", map { "$_ => $s->{notes}{$_}" } keys %{ $s->{notes} } ),
	"\n";
