#!/usr/bin/env perl
use UR;
use Test::More tests => 8;

note("*** class 1: like-clause ***");

class Acme::Foo { has => [qw/a b c/] };

sub Acme::Foo::__load__ {
    return 
        [qw/id a b c/],
        [
            [100, "a100", "b100", "c100"],
            [200, "a200", "b200", "c200"],
            [300, "a300", "b300", "c300"],
        ]
}

my @f = Acme::Foo->get("b like" => "%2%");
is(scalar(@f), 1, "got one object with a like-clause");
is($f[0]->id, 200, "it is correct");



note("*** class 2: in-clause ***");

class Acme::Bar { 
    has => [
        a => { is => 'Text' },
        b => { is => 'Text' },
        c => { is => 'Text' },
        foo => { is => "Acme::Foo", id_by => "foo_id" },
    ] 
};

sub Acme::Bar::__load__ {
    return 
        [qw/id a b c foo_id/],
        [
            [10, "a100", "b100", "c100", 100],
            [20, "a200", "b200", "c200", 200],
            [30, "a300", "b300", "c300", 300],
        ]
}

my @b = Acme::Bar->get("c" => ['c200', 'c300']);
is(scalar(@b), 2, "got two objects with an in-clause");
is($b[0]->id, 20, "first is correct");
is($b[1]->id, 30, "second is correct");



note("*** in-memory joins ***");

my @b2 = Acme::Bar->get("foo.a" => "a100");
is(scalar(@b2), 1, "got one object with a join to another class");
is($b2[0]->id, 10, "it is the correct object");
is($b2[0]->foo->a, "a100", "value is correct");



