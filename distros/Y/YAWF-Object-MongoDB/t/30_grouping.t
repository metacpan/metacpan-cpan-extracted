use Test::More tests => 13;

use_ok('YAWF::Object::MongoDB');
use_ok('t::lib::Forest');

for ('birch','oak','deer','boar','color') {
ok(t::lib::Forest->can($_),'Check '.$_.' method');}

# Check groups
is(ref($t::lib::Forest::GROUPS),'ARRAY','Grouping ref type');
SKIP : {
	skip "Skip further tests, because Grouping store is not an ARRAY",10 unless ref($t::lib::Forest::GROUPS) eq 'ARRAY';

	# Group 0 is build from a hash, the key order is unpredictable
	is(ref($t::lib::Forest::GROUPS->[0]),'ARRAY','Group 0 type');
	is($#{$t::lib::Forest::GROUPS->[0]},2,'Group 0 size');
	is_deeply([sort(@{$t::lib::Forest::GROUPS->[0]})],['birch','color','oak'],'Group 0 keys');

	is_deeply(
	$t::lib::Forest::GROUPS->[1],['deer','boar','color'],'Group 1');

}

is_deeply(
$t::lib::Forest::KEYGROUPS,{'birch' => [0],'oak' => [0],'deer' => [1],'boar' => [1],color => [0,1]},'Group members');
