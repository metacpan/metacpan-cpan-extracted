#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;

BEGIN { use_ok("VS::RuleEngine::TypeDecl"); }

require VS::RuleEngine::Engine;

my $obj = bless {}, "Foo";
my $type = VS::RuleEngine::TypeDecl->new($obj);
isa_ok($type, "VS::RuleEngine::TypeDecl");
ok($obj == $type->instantiate);

{
    package A;
    sub new {
        my ($pkg, @args) = @_;
        ::is($pkg, "A");
        ::is(@args, 0);
        return bless {}, $pkg;
    }
}

$type = VS::RuleEngine::TypeDecl->new("A");
$obj = $type->instantiate();
isa_ok($obj, "A");

{
    package B;
    sub new {
        my ($pkg, @args) = @_;
        ::is(@args, 2);
        ::is_deeply([@args], [qw(foo baz)]);
        return bless {}, $pkg;
    }
}

$type = VS::RuleEngine::TypeDecl->new("B", [], "foo", "baz");
$obj = $type->instantiate();

{
    package C;
    sub new {
        my ($pkg, %args) = @_;
        ::is_deeply(\%args, { foo => 1, bar => 2 });
    }
}

my $e = VS::RuleEngine::Engine->new();
$e->add_defaults(d1 => { foo => 1 });
$type = VS::RuleEngine::TypeDecl->new("C", "d1", bar => 2);
$obj = $type->instantiate($e);

$type = VS::RuleEngine::TypeDecl->new("C", [qw(d1)], bar => 2);
$obj = $type->instantiate($e);