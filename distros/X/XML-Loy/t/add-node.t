#!/usr/bin/perl
use strict;
use warnings;
use lib '../lib', '../../lib';

use Test::More tests => 12;

my $pi = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';

use_ok('XML::Loy');

my $i = 1;

ok(my $xml = XML::Loy->new('test'), 'Constructor String');
ok(my $string = $xml->to_pretty_xml, 'Pretty Print');
like($string, qr{<test />}, 'Check ' . $i++);
like($string, qr{\Q$pi\E}, 'Check ' . $i++);

ok(my $child = XML::Loy->new('child'), 'Constructor String');
ok($string = $child->to_pretty_xml, 'Pretty Print');
like($string, qr{<child />}, 'Check ' . $i++);
like($string, qr{\Q$pi\E}, 'Check ' . $i++);

ok($xml->add($child), 'Add child');
ok($string = $xml->to_pretty_xml, 'Pretty Print');

$string =~ s/\s+//g;

# Has no two pis
is($string,
   '<?xmlversion="1.0"encoding="UTF-8"standalone="yes"?><test><child/></test>',
   'String is okay');
