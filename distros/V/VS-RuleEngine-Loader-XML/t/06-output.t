#!perl

use strict;
use warnings;

use Test::More tests => 3;

use VS::RuleEngine::Loader::XML;

my $engine = VS::RuleEngine::Loader::XML->load_string(q{
    <engine>
        <output name="output1" instanceOf="VS::RuleEngine::Output"/>
        <output name="output2" instanceOf="VS::RuleEngine::Output">
            <arg1>1</arg1>
            <arg2/>
        </output>
    </engine>
});

is_deeply([sort $engine->outputs], [qw(output1 output2)]);

my $output = $engine->_get_output("output1");
is($output->_pkg, "VS::RuleEngine::Output");

$output = $engine->_get_output("output2");
is_deeply($output->_args, [ arg1 => 1, arg2 => undef ]);
