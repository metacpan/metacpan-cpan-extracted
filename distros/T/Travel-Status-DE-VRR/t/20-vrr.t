#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use utf8;

use Encode qw(decode);
use File::Slurp qw(slurp);
use Test::More tests => 113;

BEGIN {
	use_ok('Travel::Status::DE::VRR');
}
require_ok('Travel::Status::DE::VRR');

my $xml = slurp('t/in/essen_hb.xml');

my $status = Travel::Status::DE::VRR->new_from_xml(xml => $xml);

isa_ok($status, 'Travel::Status::DE::EFA');
can_ok($status, qw(errstr results));

is($status->errstr, undef, 'no error');
is_deeply([$status->identified_data], [qw[Essen Hauptbahnhof]], 'identified_data');

my @results = $status->results;

for my $result (@results) {
	isa_ok($result, 'Travel::Status::DE::EFA::Result');
	can_ok($result, qw(date destination info line time type platform));
}

is($results[0]->destination, 'Düsseldorf Hbf', 'first result: destination ok');
is($results[0]->info, 'Bordrestaurant', 'first result: no info');
is($results[0]->line, 'ICE 946 Intercity-Express', 'first result: line ok');
is($results[0]->date, '16.11.2011', 'first result: real date ok');
is($results[0]->time, '09:40', 'first result: real time ok');
is($results[0]->delay, 4, 'first result: delay 4');
is($results[0]->sched_date, '16.11.2011', 'first result: scheduled date ok');
is($results[0]->sched_time, '09:36', 'first result: scheduled time ok');
is($results[0]->mot_name, 'zug', 'first result: mot_name ok');
#is($results[0]->platform, '1', 'first result: platform ok');
#is($results[0]->platform_db, 1, 'first result: platform_db ok');

is($results[3]->destination, 'Mülheim Heißen Kirche', 'fourth result: destination ok');
is($results[3]->info, 'Ab (H) Heißen Kirche, Umstieg in den SEV Ri. Mülheim Hbf.', 'fourth result: no info');
is($results[3]->line, '18', 'fourth result: line ok');
is($results[3]->date, '16.11.2011', 'fourth result: real date ok');
is($results[3]->time, '09:39', 'fourth result: real time ok');
is($results[3]->delay, undef, 'fourth result: delay undef');
is($results[3]->sched_date, '16.11.2011', 'fourth result: scheduled date ok');
is($results[3]->sched_time, '09:39', 'fourth result: scheduled time ok');
is($results[3]->mot_name, 'u-bahn', 'fourth result: mot_name ok');
#is($results[3]->platform, '2', 'fourth result: platform ok');
#is($results[3]->platform_db, 0, 'fourth result: platform_db ok');

is($results[-1]->destination, 'Hamm (Westf)', 'last result: destination ok');
is($results[-1]->info, 'Fahrradmitnahme begrenzt möglich', 'last result: info ok');
is($results[-1]->delay, 12, 'last result: delay 12');
is($results[-1]->line, 'RE1', 'last result: line ok');
is($results[-1]->date, '16.11.2011', 'last result: date ok');
is($results[-1]->time, '10:05', 'last result: time ok');
is($results[-1]->sched_date, '16.11.2011', 'first result: scheduled date ok');
is($results[-1]->sched_time, '09:53', 'last result: scheduled time ok');
is($results[-1]->mot_name, 'zug', 'last result: mot_name ok');
#is($results[-1]->platform, '6', 'last result: platform ok');
#is($results[-1]->platform_db, 1, 'last result: platform ok');
