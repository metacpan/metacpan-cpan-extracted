#!/usr/bin/perl
use strict;
use warnings;

use lib '../lib';
use lib '../../lib';

use Test::More tests => 40;

my $pi = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';

use_ok('XML::Loy');

my $i = 1;

ok(my $xml = XML::Loy->new('test'), 'Constructor String');
ok(my $string = $xml->to_pretty_xml, 'Pretty Print');
like($string, qr{<test />}, 'Check ' . $i++);
like($string, qr{\Q$pi\E}, 'Check ' . $i++);

ok($xml->add('try'), 'Add 1');
ok(my $try = $xml->add('try'), 'Add 2');

ok($xml->set('once' => { foo => 'bar' } ), 'Set 1');

is($xml->at('test')->attr('loy:once'), '(once)', 'Loy once att');

ok($xml->at('once[foo=bar]'), 'Find once');

ok($xml->add('once' => { foo => 'bar2' } ), 'Add 3');

ok($xml->at('once[foo=bar]'), 'Find once');
ok($xml->at('once[foo=bar2]'), 'Find once');

ok(my $once = $xml->set('once' => { ver => 'such'}), 'Set 2');

ok($xml->at('once[ver=such]'), 'Find once');
ok(!$xml->at('once[foo]'), 'Find once');

ok($once->set('once' => { foo => 'bar3' } ), 'Set 1');

ok($xml->at('once[ver=such]'), 'Find once');
ok($xml->at('once[foo=bar3]'), 'Find once');

ok($once->set('once' => { foo => 'bar4' } ), 'Set 2');

ok($xml->at('once[ver=such]'), 'Find once');
ok(!$xml->at('once[foo=bar3]'), 'Find once');
ok($xml->at('once[foo=bar4]'), 'Find once');

ok($once->add('once' => { foo => 'bar5' } ), 'Add');
ok($once->add('once' => { foo => 'bar6' } ), 'Add');

ok($xml->at('once[ver=such]'), 'Find once');
is($xml->find('once[foo]')->size, 3, 'Find once');

ok($try->set(once => { foo => 'bar7'}), 'Set 3');
ok($xml->set(once => { foo => 'bar8'} => undef, 'Yeah'), 'Set 4');
ok($xml->set(once => { foo => 'bar9'}), 'Set 5');
ok($xml->set(once => { foo => 'bar10'} => undef, 'Huhu'), 'Set 6');

ok($try->set(subject => 'Peter'), 'Set 7');

is($xml->at('subject')->text, 'Peter', 'Text');

ok($try->set(subject => 'Mark'), 'Set 8');

is($xml->at('subject')->text, 'Mark', 'Text');

ok($xml->set(subject => 'Yvonne'), 'Set 9');

is($xml->at('subject')->text, 'Mark', 'Get');
is($xml->at('try subject')->text, 'Mark', 'Get');
is($xml->find('subject')->size, 2, 'Size');

# Invalid elements
ok(!$xml->set('not valid'), 'No valid Element');
