#!perl

use strict;
use warnings;

use Test::More tests => 12;
use Test::Exception;

BEGIN { use_ok("VS::RuleEngine::Loader::XML"); }

my $engine = VS::RuleEngine::Loader::XML->load_string(q{
    <engine>
    </engine>
});
ok(defined $engine);
isa_ok($engine, "VS::RuleEngine::Engine");

$engine = VS::RuleEngine::Loader::XML->load_file("t/basic.xml");
ok(defined $engine);
isa_ok($engine, "VS::RuleEngine::Engine");

# Some errors
dies_ok {
    VS::RuleEngine::Loader::XML->load_file("t/01-basic.t");
};

dies_ok {
    VS::RuleEngine::Loader::XML->load_string("NO XML");
};

throws_ok {
    VS::RuleEngine::Loader::XML->load_string("<foo></foo>");
} qr/Expected root node 'engine' but found 'foo'/;

throws_ok {
    VS::RuleEngine::Loader::XML->load_string("<engine><foo/></engine>");
} qr/Don't know how to handle 'foo'/;

throws_ok {
    VS::RuleEngine::Loader::XML->load_string("<engine><input/></engine>");
} qr/input is missing mandatory attribute 'name'/;

throws_ok {
    VS::RuleEngine::Loader::XML->load_string("<engine><input name=\"input1\"/></engine>");
} qr/input is missing mandatory attribute 'instanceOf'/;

dies_ok {
    VS::RuleEngine::Loader::XML->load_string("<engine><input name=\"input1\" instanceOf=\"VS::RuleEngine::Loader::XML::MockInput\"/></engine>");
};

