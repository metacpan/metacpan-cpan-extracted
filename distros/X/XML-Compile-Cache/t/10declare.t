#!/usr/bin/env perl
use warnings;
use strict;

use lib 'lib';
use Test::More tests => 43;

use XML::Compile::Util qw/SCHEMA2001 pack_type/;
use Log::Report 'try';
our $SchemaNS = SCHEMA2001;
our $TestNS   = 'http://test-types';

use XML::Compile::Cache;
use XML::Compile::Tester;

use XML::LibXML;
my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');

my $cache = XML::Compile::Cache->new
 ( prefixes => [ me => $TestNS ]
 );

isa_ok($cache, 'XML::Compile::Cache');
isa_ok($cache, 'XML::Compile::Schema');

$cache->importDefinitions(<<__SCHEMA);
<schema targetNamespace="$TestNS"
        xmlns="$SchemaNS"
        xmlns:me="$TestNS"
        elementFormDefault="qualified">

<element name="test1" type="int" />
<element name="test2" type="int" />
<element name="test3" type="int" />
<element name="test4" type="int" />

</schema>
__SCHEMA

sub list_declared($)
{   my $c = shift;
    my $b = '';
    open my $f, '>', \$b or die "$!";
    $c->printIndex($f, kinds => 'element');
    close $f;
    $b;
}

my $list = list_declared($cache);
is($list, <<__LIST, 'nothing declared');
namespace: http://test-types
   source: SCALAR
    test1
    test2
    test3
    test4
__LIST

$cache->declare(READER => pack_type $TestNS, 'test1');
$cache->declare(RW     => "me:test2");
$cache->declare(WRITER => "{$TestNS}test3");

$list = list_declared($cache);
is($list, <<__LIST, 'three declared');
namespace: http://test-types
   source: SCALAR
 r  test1
 rw test2
  w test3
    test4
__LIST

# The reader

my $r1 = $cache->reader('me:test1');
ok(defined $r1, 'got reader test1');
isa_ok($r1, 'CODE');
my $v1 = $r1->("<me:test1 xmlns:me=\"$TestNS\">42</me:test1>");
cmp_ok($v1, '==', 42, 'test parsing');

my $r1b = $cache->reader('me:test1');
cmp_ok($r1b, '==', $r1, 'cached code ref');

my $w1 = try { $cache->writer('me:test1') };
my $msg = $@ ? $@->wasFatal->message : '';

ok(!defined $w1, 'no writer for test1 declared');
is($msg->toString, 'type me:test1 is only declared as reader');

# reader and writer

my $r2 = $cache->reader('me:test2');
ok(defined $r2, 'got reader test2');
isa_ok($r2, 'CODE');
my $v2 = $r2->("<me:test2 xmlns:me=\"$TestNS\">44</me:test2>");
cmp_ok($v2, '==', 44, 'test parsing');

my $r2b = $cache->reader('me:test2');
cmp_ok($r2b, '==', $r2, 'cached code ref');

my $w2 = $cache->writer('me:test2');
ok(defined $w2, 'got writer test2');
isa_ok($w2, 'CODE');

$v2 = $w2->($doc, 44);
isa_ok($v2, 'XML::LibXML::Element');
compare_xml($v2, "<me:test2 xmlns:me=\"$TestNS\">44</me:test2>"); 

my $w2b = $cache->writer('me:test2');
cmp_ok($w2b, '==', $w2, 'cached code ref');

# The writer

my $w3 = $cache->writer('me:test3');
ok(defined $w3, 'got writer test3');
isa_ok($w3, 'CODE');

my $v3 = $w3->($doc, 43);
isa_ok($v3, 'XML::LibXML::Element');
compare_xml($v3, "<me:test3 xmlns:me=\"$TestNS\">43</me:test3>");

my $w3b = $cache->writer('me:test3');
cmp_ok($w3b, '==', $w3, 'cached code ref');

my $r3 = try { $cache->reader('me:test3') };
$msg   = $@ ? $@->wasFatal->message : '';
ok(!defined $r3, 'no reader for test3 declared');
is($msg->toString, 'type me:test3 is only declared as writer');

# No reader nor writer

my $r4 = try { $cache->reader('me:test4') };
$msg   = $@ ? $@->wasFatal->message : '';
ok(!defined $r4, 'no reader for test4 declared');
is($msg->toString, 'type me:test4 is not declared');

my $w4 = try { $cache->writer('me:test4') };
$msg = $@ ? $@->wasFatal->message : '';
ok(!defined $w4, 'no writer for test4 declared');
is($msg->toString, 'type me:test4 is not declared');

# Allow undeclared

ok(!$cache->allowUndeclared,   'default not undeclared');
ok($cache->allowUndeclared(1), 'set allow undeclared');
ok($cache->allowUndeclared,    'allow undeclared');

my $r5 = $cache->reader('me:test4');
ok(defined $r5, 'got reader test4');
isa_ok($r5, 'CODE');
my $v5 = $r5->("<me:test4 xmlns:me=\"$TestNS\">45</me:test4>");
cmp_ok($v5, '==', 45, 'test parsing');

my $r5b = $cache->reader('me:test4');
cmp_ok($r5b, '==', $r5, 'cached code ref');

my $w5 = $cache->writer('me:test4');
ok(defined $w5, 'got writer test4');
isa_ok($w5, 'CODE');

my $v5b = $w5->($doc, 46);
isa_ok($v5b, 'XML::LibXML::Element');
compare_xml($v5b, "<me:test4 xmlns:me=\"$TestNS\">46</me:test4>");

my $w5b = $cache->writer('me:test4');
cmp_ok($w5b, '==', $w5, 'cached code ref');

$list = list_declared($cache);
is($list, <<__LIST, 'all are compiled');
namespace: http://test-types
   source: SCALAR
 R  test1
 RW test2
  W test3
 RW test4
__LIST

