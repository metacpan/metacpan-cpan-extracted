#!perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

use VS::RuleEngine::Loader::XML;

my $engine = VS::RuleEngine::Loader::XML->load_string(q{
    <engine>
        <action name="action1" instanceOf="VS::RuleEngine::Action"/>
        <action name="action2" instanceOf="VS::RuleEngine::Action"/>
        
        <rule name="rule1" instanceOf="VS::RuleEngine::Rule"/>
        <rule name="rule2" instanceOf="VS::RuleEngine::Rule"/>
        
        <ruleset name="all_rules" rulesMatchingName=".*"/>
        
        <run action="action1">
            <rule>rule1</rule>
        </run>
        
        <run action="action2">
            <ruleset>all_rules</ruleset>
        </run>
    </engine>
});

is_deeply($engine->_get_rule_actions("rule1"), [qw(action1 action2)]);
is_deeply($engine->_get_rule_actions("rule2"), [qw(action2)]);

throws_ok {
    VS::RuleEngine::Loader::XML->load_string("<engine><run/></engine>");
} qr/Missing attribute 'action' for element 'run'/;

throws_ok {
    VS::RuleEngine::Loader::XML->load_string("<engine><run action=\"foo\"/></engine>");
} qr/No action named 'foo' exists/;