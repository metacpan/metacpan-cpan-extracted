#!/usr/bin/perl
use strict;
use warnings;

use lib '../lib';
use lib '../../lib';

use Test::More tests => 41;

my $pi = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';

use_ok('XML::Loy');

ok(my $xml = XML::Loy->new('test'), 'Constructor String');
like($xml->to_pretty_xml, qr{<test />}, 'Pretty Print');
like($xml->to_pretty_xml, qr{\Q$pi\E}, 'Pretty Print');

ok($xml = XML::Loy->new('test' => { foo => 'bar' }), 'Constructor String with att');
like($xml->to_pretty_xml, qr{<test foo="bar" />}, 'Pretty Print');
like($xml->to_pretty_xml, qr{\Q$pi\E}, 'Pretty Print');

ok($xml = XML::Loy->new('test' => { foo => 'bar', a => 'b' }), 'Constructor String with att');
like($xml->to_pretty_xml, qr{<test}, 'Pretty Print');
like($xml->to_pretty_xml, qr{foo="bar"}, 'Pretty Print');
like($xml->to_pretty_xml, qr{a="b"}, 'Pretty Print');
like($xml->to_pretty_xml, qr{\Q$pi\E}, 'Pretty Print');

ok($xml = XML::Loy->new('test' => { foo => 'bar', a => 'b' } => 'Text'), 'Constructor String with att and Text');
like($xml->to_pretty_xml, qr{<test}, 'Pretty Print');
like($xml->to_pretty_xml, qr{foo="bar"}, 'Pretty Print');
like($xml->to_pretty_xml, qr{a="b"}, 'Pretty Print');
like($xml->to_pretty_xml, qr{>Text<}, 'Pretty Print');
like($xml->to_pretty_xml, qr{\Q$pi\E}, 'Pretty Print');

ok($xml = XML::Loy->new('test' => { foo => 'bar', a => 'b' } => 0), 'Constructor String with att and Null');
like($xml->to_pretty_xml, qr{<test}, 'Pretty Print');
like($xml->to_pretty_xml, qr{foo="bar"}, 'Pretty Print');
like($xml->to_pretty_xml, qr{a="b"}, 'Pretty Print');
like($xml->to_pretty_xml, qr{>0<}, 'Pretty Print');
like($xml->to_pretty_xml, qr{\Q$pi\E}, 'Pretty Print');

ok($xml = XML::Loy->new(test => 'Text'), 'Constructor String with text');
like($xml->to_pretty_xml, qr{<test}, 'Pretty Print');
like($xml->to_pretty_xml, qr{>Text<}, 'Pretty Print');
like($xml->to_pretty_xml, qr{\Q$pi\E}, 'Pretty Print');

ok($xml = XML::Loy->new(test => {} => 'Text'), 'Constructor String with text');
like($xml->to_pretty_xml, qr{<test}, 'Pretty Print');
like($xml->to_pretty_xml, qr{>Text<}, 'Pretty Print');
like($xml->to_pretty_xml, qr{\Q$pi\E}, 'Pretty Print');

ok($xml = XML::Loy->new(test => 'Text' => 'Comment'),
   'Constructor String with text and comment');
like($xml->to_pretty_xml, qr{<test}, 'Pretty Print');
like($xml->to_pretty_xml, qr{>Text<}, 'Pretty Print');
like($xml->to_pretty_xml, qr{<!-- Comment -->}, 'Pretty Print');
like($xml->to_pretty_xml, qr{\Q$pi\E}, 'Pretty Print');

ok($xml = XML::Loy->new(test => undef, 'Comment'),
   'Constructor String with comment and without text');
like($xml->to_pretty_xml, qr{<test />}, 'Pretty Print');
like($xml->to_pretty_xml, qr{<!-- Comment -->}, 'Pretty Print');
like($xml->to_pretty_xml, qr{\Q$pi\E}, 'Pretty Print');
