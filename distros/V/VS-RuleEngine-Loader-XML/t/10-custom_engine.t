#!perl

package Test::VS::RuleEngine::Engine;

use strict;
use warnings;

use Test::More tests => 2;

use VS::RuleEngine::Loader::XML;

use base qw(VS::RuleEngine::Engine);

my $engine = VS::RuleEngine::Loader::XML->load_string(q{
    <engine instanceOf="Test::VS::RuleEngine::Engine">
    </engine>
});

ok(defined $engine);
isa_ok($engine, "Test::VS::RuleEngine::Engine");