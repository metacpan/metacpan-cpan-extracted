#!/usr/bin/perl
use strict;
use warnings;

use lib '../lib';
use lib '../../lib';

use Test::More tests => 25;

my $pi = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';

use_ok('XML::Loy');

my $i = 1;

ok(my $xml = XML::Loy->new('root'), 'Constructor String');
ok(my $child = $xml->add('test'), 'Add child');
ok(my $string = $xml->to_pretty_xml, 'Pretty Print');
like($string, qr{<test />}, 'Check ' . $i++);
like($string, qr{\Q$pi\E}, 'Check ' . $i++);

ok($child->comment('MyComment'), 'Set comment');
ok($string = $xml->to_pretty_xml, 'Pretty Print');
like($string, qr{<!-- MyComment -->}, 'Check ' . $i++);

ok(my $obj = $child->add(test => { foo => 'bar' }), 'Add object');

ok($obj->comment('My New Comment'), 'New Comment');

ok($string = $xml->to_pretty_xml, 'Pretty Print');

$string =~ s/\s//g;

like($string, qr{<test>}, 'Check ' . $i++);
like($string, qr{</test>}, 'Check ' . $i++);
like($string, qr{<!--MyComment-->}, 'Check ' . $i++);
like($string, qr{<!--MyNewComment-->}, 'Check ' . $i++);
like($string, qr{<!--MyNewComment--><testfoo}, 'Check ' . $i++);
ok($obj->comment('My New Comment 2'), 'New Comment');

ok($string = $xml->to_pretty_xml, 'Pretty Print');

$string =~ s/\s//g;
like($string, qr{<!--MyNewCommentMyNewComment2--><testfoo}, 'Check ' . $i++);


ok($xml = XML::Loy->new('entry'), 'New document');
ok($obj = XML::Loy->new('child'), 'Add child');

ok($obj = $xml->add($obj), 'Add child');

$obj->comment('Comment1')->comment('Comment2')->comment('Comment3');

ok($string = $xml->to_pretty_xml, 'Pretty Print');

$string =~ s/\s//g;
like($string, qr{<!--Comment1Comment2Comment3--><child}, 'Check ' . $i++);
