#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 15;

my $m; BEGIN { use_ok($m = "Verby::Config::Data::Mutable") };

can_ok($m, "new");
isa_ok(my $p = $m->new, $m);


can_ok($p, "get");
is($p->get("foo"), undef, "get('foo') is undef");

can_ok($p, "AUTOLOAD");
is($p->foo, $p->get("foo"), "get('foo') is the same as ->foo");

$p->foo("value");

is($p->get("foo"), "value", "get('foo') is value");
is($p->foo, $p->get("foo"), "get('foo') is the same as ->foo");

can_ok($p, "derive");
isa_ok(my $c = $p->derive, $m);

is($c->foo, $p->foo, "child inherits parents values");

$c->foo("blah");
is($c->foo, "blah", "child added value");
is($p->foo, "value", "parent unchanged");

$c->export("foo");
is($p->foo, $c->foo, "'foo' exported to parent");

