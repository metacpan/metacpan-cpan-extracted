#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use utf8;

use File::Slurp qw(slurp);
use Test::More tests => 10;

BEGIN {
	use_ok('Travel::Status::DE::VRR');
}
require_ok('Travel::Status::DE::VRR');

my $xml = slurp('t/in/essen_alfredusbad_ambiguous.xml');

my $status = Travel::Status::DE::VRR->new_from_xml(xml => $xml);

isa_ok($status, 'Travel::Status::DE::VRR');
can_ok($status, qw(errstr results));

$status->check_for_ambiguous();

is($status->errstr, 'ambiguous name parameter', 'errstr ok');

is_deeply([$status->place_candidates], [], 'place candidates ok');
is_deeply([$status->name_candidates], ['Alfredusbad', 'Am Alfredusbad'], 'name candidates ok');

is_deeply([$status->lines], [], 'no lines');
is_deeply([$status->results], [], 'no results');
is_deeply([$status->identified_data], [qw[Essen Alfredusbad]], 'identified data');
