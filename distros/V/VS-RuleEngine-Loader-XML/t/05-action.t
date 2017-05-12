#!perl

use strict;
use warnings;

use Test::More tests => 3;

use VS::RuleEngine::Loader::XML;

my $engine = VS::RuleEngine::Loader::XML->load_string(q{
    <engine>
        <action name="action1" instanceOf="VS::RuleEngine::Action"/>
        <action name="action2" instanceOf="VS::RuleEngine::Action">
            <arg1>1</arg1>
            <arg2/>
        </action>
    </engine>
});

is_deeply([sort $engine->actions], [qw(action1 action2)]);

my $action = $engine->_get_action("action1");
is($action->_pkg, "VS::RuleEngine::Action");

$action = $engine->_get_action("action2");
is_deeply($action->_args, [ arg1 => 1, arg2 => undef ]);
