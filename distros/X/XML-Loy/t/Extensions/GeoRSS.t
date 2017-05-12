#!/usr/bin/perl
use strict;
use warnings;

use lib 'lib', '../lib', '../../lib';

use Test::More tests => 77;

use_ok('XML::Loy::Atom');

my $atom = XML::Loy::Atom->new('entry');
$atom->extension(-GeoRSS);
$atom->author(name => 'Fry');

my $where = $atom->geo_where;

ok($where->geo_point(45.34, -23.67),'Add point');
ok(!$where->geo_point(45.34, -23.67, 45),'Add wrong point');

ok($where->geo_line(45.34, -23.67, 16.3, 17.89), 'Add line');
ok($where->geo_line(45.34, -23.67, 16.3, 17.89, 15.4, -5.4), 'Add line');
ok(!$where->geo_line(45.34, -23.67), 'Add line wrong');
ok(!$where->geo_line(45.34, -23.67, 16.3, 17.89, 15.4), 'Add line wrong');

ok($where->geo_polygon(45.34, -23.67, 16.3, 17.89, 15.4, -5.4), 'Add poly');
ok($where->geo_polygon(45.34, -23.67, 16.3, 17.89, 15.4, -5.4, 45.34, -23.67), 'Add poly');
ok(!$where->geo_polygon(45.34, -23.67), 'Add poly wrong');
ok(!$where->geo_polygon(45.34, -23.67, 16.3, 17.89), 'Add poly wrong');
ok(!$where->geo_polygon(45.34, -23.67, 16.3, 17.89, 15.4, -5.4, -5.8), 'Add poly wrong');

ok($where->geo_box(45.34, -23.67, 16.3, 17.89), 'Add box');
ok(!$where->geo_box(45.34, -23.67, 16.3, 17.89, 15.4, -5.4), 'Add box wrong');
ok(!$where->geo_box(45.34, -23.67), 'Add box wrong');
ok(!$where->geo_box(45.34, -23.67, 16.3, 17.89, 15.4), 'Add box wrong');

ok($where->geo_circle(45.34, -23.67, 90), 'Add circle');
ok(!$where->geo_circle(45.34, -23.67), 'Add circle wrong');
ok(!$where->geo_circle(45.34, -23.67, 16.3, 17.89), 'Add circle wrong');

ok($where->geo_property(
  relationshipTag => 'tag1',
  featureTypeTag => [qw/tag2 tag3 tag4/],
  featureName => ['tag5'],
  foo => 'bar'
), 'Add properties');


ok($where->geo_floor(5), 'Add floor');
ok($where->geo_elev(19), 'Add even');
ok($where->geo_radius(500), 'Add radius');

is($atom->at('point')->text, '45.34 -23.67', 'Point');
is($atom->geo_point->[0], 45.34, 'X');
is($atom->geo_point->[1], -23.67, 'y');

is($atom->find('line')->[0]->text, '45.34 -23.67 16.3 17.89', 'Line');
is($atom->geo_line->[0]->[0], 45.34, 'StartX');
is($atom->geo_line->[0]->[1], -23.67, 'StartY');
is($atom->geo_line->[1]->[0], 16.3, 'EndX');
is($atom->geo_line->[1]->[1], 17.89, 'EndY');

is($atom->find('line')->[1]->text, '45.34 -23.67 16.3 17.89 15.4 -5.4', 'Line');
is($atom->geo_line(1)->[0]->[0], 45.34, 'StartX');
is($atom->geo_line(1)->[0]->[1], -23.67, 'StartY');
is($atom->geo_line(1)->[1]->[0], 16.3, 'MiddleX');
is($atom->geo_line(1)->[1]->[1], 17.89, 'MiddleY');
is($atom->geo_line(1)->[2]->[0], 15.4, 'EndX');
is($atom->geo_line(1)->[2]->[1], -5.4, 'EndY');


is($atom->find('polygon')->[0]->text, '45.34 -23.67 16.3 17.89 15.4 -5.4 45.34 -23.67', 'Polygon');
is($atom->geo_polygon->[0]->[0],  45.34, 'Start1');
is($atom->geo_polygon->[0]->[1], -23.67, 'Start2');
is($atom->geo_polygon->[1]->[0],  16.3,  'Start3');
is($atom->geo_polygon->[1]->[1],  17.89, 'Start4');
is($atom->geo_polygon->[2]->[0],  15.4,  'Start5');
is($atom->geo_polygon->[2]->[1],  -5.4,  'Start6');
is($atom->geo_polygon->[3]->[0],  45.34, 'Start7');
is($atom->geo_polygon->[3]->[1], -23.67, 'Start8');

is($atom->find('polygon')->[1]->text, '45.34 -23.67 16.3 17.89 15.4 -5.4 45.34 -23.67', 'Polygon');

is($atom->find('box')->[0]->text, '45.34 -23.67 16.3 17.89', 'Box');
is($atom->geo_box->[0]->[0], 45.34,  'tl');
is($atom->geo_box->[0]->[1], -23.67, 'tr');
is($atom->geo_box->[1]->[0], 16.3,   'bl');
is($atom->geo_box->[1]->[1], 17.89,  'br');

is($atom->at('circle')->text, '45.34 -23.67 90', 'Circle');
is($atom->geo_circle->[0]->[0], 45.34, 'StartX');
is($atom->geo_circle->[0]->[1], -23.67, 'StartY');
is($atom->geo_circle->[1], 90, 'Radius');

is($atom->find('relationshiptag')->[0]->text, 'tag1', 'Property1');
ok(!$atom->find('relationshiptag')->[1], 'Property2');
my $ftt = $atom->find('featuretypetag');
is($ftt->[0]->text, 'tag2', 'Property3');
is($ftt->[1]->text, 'tag3', 'Property4');
is($ftt->[2]->text, 'tag4', 'Property5');
ok(!$ftt->[3], 'Property6');
is($atom->find('featurename')->[0]->text, 'tag5', 'Property7');
ok(!$atom->find('featurename')->[1], 'Property8');
ok(!$atom->at('foo'), 'Property9');

is($atom->at('floor')->text, '5', 'Floor');
is($atom->at('elev')->text, '19', 'Even');
is($atom->at('radius')->text, '500', 'Radius');

is($atom->at('author > name')->text, 'Fry', 'Atom Check');
my $geo_ns = 'http://www.georss.org/georss';
is($atom->at('point')->namespace, $geo_ns, 'Namespace');
is($atom->at('line')->namespace, $geo_ns, 'Namespace');
is($atom->at('box')->namespace, $geo_ns, 'Namespace');
is($atom->at('circle')->namespace, $geo_ns, 'Namespace');
is($atom->at('polygon')->namespace, $geo_ns, 'Namespace');
is($atom->at('author')->namespace, 'http://www.w3.org/2005/Atom', 'Namespace');
is($atom->at('name')->namespace, 'http://www.w3.org/2005/Atom', 'Namespace');

__END__
