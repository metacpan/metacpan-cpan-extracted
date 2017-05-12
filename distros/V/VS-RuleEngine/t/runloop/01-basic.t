#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;
use Test::Exception;

use Scalar::Util qw(refaddr);

BEGIN { use_ok("VS::RuleEngine::Runloop"); }

use VS::RuleEngine::Constants;
use VS::RuleEngine::Engine;

my $runloop = VS::RuleEngine::Runloop->new();
ok(defined $runloop);
isa_ok($runloop, "VS::RuleEngine::Runloop");
ok(refaddr $runloop == $$runloop);

throws_ok {
    $runloop->add_engine(undef);
} qr/Engine is undefined/;

throws_ok {
    $runloop->add_engine("foo");
} qr/Engine is not a VS::RuleEngine::Engine instance/;

throws_ok {
    $runloop->add_engine(bless {}, "Foo");
} qr/Engine is not a VS::RuleEngine::Engine instance/;

my $engine = VS::RuleEngine::Engine->new();

lives_ok {
    $runloop->add_engine($engine);
};

throws_ok {
    $runloop->add_engine($engine);
} qr/Engine already exists/;

