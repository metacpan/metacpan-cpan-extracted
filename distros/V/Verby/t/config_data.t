#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 31;
use Test::Exception;
use Test::MockObject;

my $m; BEGIN { use_ok($m = "Verby::Config::Data") };

can_ok($m, "new");
isa_ok(my $p = $m->new, $m);


can_ok($p, "get");
is($p->get("foo"), undef, "get('foo') is undef");

can_ok($p, "AUTOLOAD");
is($p->foo, $p->get("foo"), "get('foo') is the same as ->foo");

can_ok($p, "data");
isa_ok($p->data, "HASH", "data");
$p->data->{foo} = "value";

is($p->get("foo"), "value", "get('foo') is value");
is($p->foo, $p->get("foo"), "get('foo') is the same as ->foo");

can_ok($p, "derive");
isa_ok(my $c = $p->derive, $m);

can_ok($c, "parents");
is_deeply([ $c->parents ], [$p], "c->parents is correct");

is($c->foo, $p->foo, "child inherits parents values");

$c->data->{foo} = "blah";
is($c->foo, "blah", "child added value");
is($p->foo, "value", "parent unchanged");

{
	package Config::Foo;
	use Moose;

	extends qw/Verby::Config::Data/;
}

isa_ok(my $o = $c->derive("Config::Foo"), $m);
isa_ok($o, "Config::Foo");

is($o->foo, $c->foo, "grandchild inherits childs value");
delete $c->data->{foo};
is($o->foo, $p->foo, "when key deleted in child, grandchild gets parent");

dies_ok { $p->foo("new") } "can't set immutable object";

my $logger = Test::MockObject->new;
$logger->set_true("warn");

no warnings 'redefine';
sub Log::Dispatch::Config::instance { $logger };

{
	my @parents = map { $m->new } 1 .. 3;
	my $child = $m->new(@parents);

	$parents[0]->data->{foo} = "moose";
	is( $child->foo, "moose", "parent value inherited" );

	ok( !$logger->called("warn"), "no warning" );

	$parents[1]->data->{foo} = "elk";
	is( $child->foo, undef, "when parents conflict, nobody wins");

	$logger->called_ok("warn");
}

$logger->clear;

{
	my $grandparent = $m->new;
	my @parents = map { $m->new($grandparent) } 1 .. 3;
	my $child = $m->new(@parents);

	$grandparent->data->{foo} = "moose";
	is( $child->foo, "moose", "no conflict in diamond inheritence" );

	ok( !$logger->called("warn"), "no warning" );

	$parents[0]->data->{foo} = "elk";
	is( $child->foo, undef, "diamond inheritence conflict, nobody wins");
	
	$logger->called_ok("warn");
}
