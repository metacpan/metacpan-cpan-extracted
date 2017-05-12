#!perl

use strict;
use warnings;

use Test::More tests => 6;

use VS::RuleEngine::Loader::XML;

my $engine = VS::RuleEngine::Loader::XML->load_string(q{
    <engine>
        <defaults name="d1">
            <foo>1</foo>
        </defaults>

        <defaults name="d2">
            <bar>2</bar>
        </defaults>

        <action name="action1" instanceOf="VS::RuleEngine::Action" defaults="d1"/>
        <action name="action2" instanceOf="VS::RuleEngine::Action" defaults="d1 d2"/>
        <action name="action3" instanceOf="VS::RuleEngine::Action" defaults="d1, d2"/>
    </engine>
});

is_deeply([sort $engine->defaults], [qw(d1 d2)]);

my $defaults = $engine->get_defaults("d1");
is_deeply($defaults, { foo => 1 });

$defaults = $engine->get_defaults("d2");
is_deeply($defaults, { bar => 2 });

is_deeply($engine->_get_action("action1")->_defaults, [qw(d1)]);
is_deeply($engine->_get_action("action2")->_defaults, [qw(d1 d2)]);
is_deeply($engine->_get_action("action3")->_defaults, [qw(d1 d2)]);