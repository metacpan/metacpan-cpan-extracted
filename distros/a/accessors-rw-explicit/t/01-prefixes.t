#!/usr/bin/perl

package Test::Object;
use accessors::rw::explicit qw/foo bar baz/;

sub new {
    return bless {}, shift;
}

package Test::Object::PBP;
use accessors::rw::explicit ({get_prefix => 'get_'}, qw/foo bar baz/);

sub new {
    return bless {}, shift;
}

package Test::Object::Camel;
use accessors::rw::explicit ({get_prefix => 'get', set_prefix => 'set'}, qw/Foo Bar Baz/);

sub new {
    return bless {}, shift;
}

package main;

use Test::More tests => 15;

my $to = Test::Object->new();

isa_ok($to, 'Test::Object');

can_ok($to, qw/foo bar baz set_foo set_bar set_baz/);

$to->set_foo( "A new foo" );
is($to->foo, "A new foo", "Foo access");

$to->set_bar( "A new bar" );
is($to->bar, "A new bar", "Bar access");

$to->set_baz( "A new baz" );
is($to->baz, "A new baz", "Baz access");

my $to_pbp = Test::Object::PBP->new();

isa_ok($to_pbp, 'Test::Object::PBP');

can_ok($to_pbp, qw/get_foo get_bar get_baz set_foo set_bar set_baz/);

$to_pbp->set_foo( "A new foo" );
is($to_pbp->get_foo, "A new foo", "Foo access");

$to_pbp->set_bar( "A new bar" );
is($to_pbp->get_bar, "A new bar", "Bar access");

$to_pbp->set_baz( "A new baz" );
is($to_pbp->get_baz, "A new baz", "Baz access");

my $to_camel = Test::Object::Camel->new();

isa_ok($to_camel, 'Test::Object::Camel');

can_ok($to_camel, qw/getFoo getBar getBaz setFoo setBar setBaz/);

$to_camel->setFoo( "A new foo" );
is($to_camel->getFoo, "A new foo", "Foo access");

$to_camel->setBar( "A new bar" );
is($to_camel->getBar, "A new bar", "Bar access");

$to_camel->setBaz( "A new baz" );
is($to_camel->getBaz, "A new baz", "Baz access");
