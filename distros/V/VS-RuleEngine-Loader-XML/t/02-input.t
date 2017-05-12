#!perl

use strict;
use warnings;

use Test::More tests => 3;

use VS::RuleEngine::Loader::XML;

my $engine = VS::RuleEngine::Loader::XML->load_string(q{
    <engine>
        <input name="input1" instanceOf="VS::RuleEngine::Input"/>
        <input name="input2" instanceOf="VS::RuleEngine::Input">
            <arg1>1</arg1>
            <arg2/>
        </input>
    </engine>
});

is_deeply([sort $engine->inputs], [qw(input1 input2)]);

my $input = $engine->_get_input("input1");
is($input->_pkg, "VS::RuleEngine::Input");

$input = $engine->_get_input("input2");
is_deeply($input->_args, [ arg1 => 1, arg2 => undef ]);
