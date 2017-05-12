#!/usr/bin/perl
use strict;
use warnings;

use lib '../lib';
use lib '../../lib';

use Test::More tests => 69;

my $pi = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';

use_ok('XML::Loy');

my $i = 1;

ok(my $xml = XML::Loy->new('test'), 'Constructor String');
ok(my $string = $xml->to_pretty_xml, 'Pretty Print');
like($string, qr{<test />}, 'Check ' . $i++);
like($string, qr{\Q$pi\E}, 'Check ' . $i++);

is($xml->namespace, undef, 'Namespace is undef');

ok($xml->add('foo'), 'Add element');
ok($string = $xml->to_pretty_xml, 'Pretty Print');
like($string, qr{<test>}, 'Check ' . $i++);
like($string, qr{</test>}, 'Check ' . $i++);
like($string, qr{<foo />}, 'Check ' . $i++);
like($string, qr{\Q$pi\E}, 'Check ' . $i++);

ok($xml->add('foo' => 'Text'), 'Add element with text');
ok($string = $xml->to_pretty_xml, 'Pretty Print');
like($string, qr{<test>}, 'Check ' . $i++);
like($string, qr{</test>}, 'Check ' . $i++);
like($string, qr{<foo>}, 'Check ' . $i++);
like($string, qr{</foo>}, 'Check ' . $i++);
like($string, qr{\Q$pi\E}, 'Check ' . $i++);

ok($xml->add('foo' => { foo => 'bar' } => 'Text'), 'Add element with text');
ok($string = $xml->to_pretty_xml, 'Pretty Print');
like($string, qr{<test>}, 'Check ' . $i++);
like($string, qr{</test>}, 'Check ' . $i++);
like($string, qr{<foo foo="bar">}, 'Check ' . $i++);
like($string, qr{>Text<}, 'Check ' . $i++);
like($string, qr{</foo>}, 'Check ' . $i++);
like($string, qr{\Q$pi\E}, 'Check ' . $i++);


ok($xml->add('chuck' => { eve => 'mint' } => 'Norris' => 'Yeah'), 'Add element with text and comment');
ok($string = $xml->to_pretty_xml, 'Pretty Print');
like($string, qr{<test>}, 'Check ' . $i++);
like($string, qr{</test>}, 'Check ' . $i++);
like($string, qr{<foo foo="bar">}, 'Check ' . $i++);
like($string, qr{<chuck eve="mint">}, 'Check ' . $i++);
like($string, qr{>Text<}, 'Check ' . $i++);
like($string, qr{>Norris<}, 'Check ' . $i++);
like($string, qr{<!-- Yeah -->}, 'Check ' . $i++);
like($string, qr{</foo>}, 'Check ' . $i++);
like($string, qr{\Q$pi\E}, 'Check ' . $i++);

ok($xml->add('chuck' => 'Norris' => 'Yeah'), 'Add element with text and comment');
ok($string = $xml->to_pretty_xml, 'Pretty Print');
like($string, qr{<test>}, 'Check ' . $i++);
like($string, qr{</test>}, 'Check ' . $i++);
like($string, qr{<foo foo="bar">}, 'Check ' . $i++);
like($string, qr{<chuck eve="mint">}, 'Check ' . $i++);
like($string, qr{<chuck>}, 'Check ' . $i++);
like($string, qr{>Text<}, 'Check ' . $i++);
like($string, qr{>Norris<}, 'Check ' . $i++);
like($string, qr{<!-- Yeah -->}, 'Check ' . $i++);
like($string, qr{</foo>}, 'Check ' . $i++);
like($string, qr{\Q$pi\E}, 'Check ' . $i++);

ok($xml->add('empty' => undef, 'Yeah 2'), 'Add element with text and comment');
ok($string = $xml->to_pretty_xml, 'Pretty Print');
like($string, qr{<test>}, 'Check ' . $i++);
like($string, qr{</test>}, 'Check ' . $i++);
like($string, qr{<foo foo="bar">}, 'Check ' . $i++);
like($string, qr{<chuck eve="mint">}, 'Check ' . $i++);
like($string, qr{<chuck>}, 'Check ' . $i++);
like($string, qr{>Text<}, 'Check ' . $i++);
like($string, qr{>Norris<}, 'Check ' . $i++);
like($string, qr{<!-- Yeah -->}, 'Check ' . $i++);
like($string, qr{<!-- Yeah 2 -->}, 'Check ' . $i++);
like($string, qr{<empty />}, 'Check ' . $i++);
like($string, qr{</foo>}, 'Check ' . $i++);
like($string, qr{\Q$pi\E}, 'Check ' . $i++);

# Invalid elements
ok(!$xml->add('not valid'), 'No valid Element');


ok($xml = XML::Loy->new('<meta />'), 'Create new document');
ok($xml->add('test'), 'Add <test />');
like($xml->to_pretty_xml, qr!<test />!, 'test is empty');
like($xml->to_pretty_xml, qr!<test />!, 'meta is empty');
