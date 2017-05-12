use strict;

use Test::More tests => 12;
use WWW::Jawbone::Up::Mock;

my $up = WWW::Jawbone::Up::Mock->connect('alan@eatabrick.org', 's3kr3t');

my @items = $up->feed('20130414');

is($items[0]->title,      '9,885 steps', 'title');
is($items[0]->type,       'move',        'type');
is($items[0]->user->name, 'Alan Berndt', 'user name');
ok(!$items[0]->reached_goal, 'goal');
isa_ok($items[0]->created, 'DateTime', 'time inflated');
is($items[0]->created->time_zone->name, 'America/Phoenix', 'time zone');

is($items[1]->title,      'for 8h 17m',  'title 2');
is($items[1]->type,       'sleep',       'type 2');
is($items[1]->user->name, 'Alan Berndt', 'user name 2');
ok($items[1]->reached_goal, 'goal 2');
isa_ok($items[1]->created, 'DateTime', 'time inflated 2');
is($items[1]->created->time_zone->name, 'America/Phoenix', 'time zone 2');
