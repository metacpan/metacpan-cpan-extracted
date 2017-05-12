#!perl

use strict;
use warnings;

use Test::More tests => 14;
use Test::Exception;

use VS::RuleEngine::Loader::XML;

my $loader = VS::RuleEngine::Loader::XML->_new();
my $engine = $loader->load_string(q{
    <engine>
        <rule name="rule1" instanceOf="VS::RuleEngine::Rule"/>
        <rule name="rule2" instanceOf="VS::RuleEngine::Rule">
            <arg1>1</arg1>
            <arg2/>
        </rule>

        <ruleset name="all_rules" rulesMatchingName=".*"/>

        <rule name="rule3" instanceOf="VS::RuleEngine::Rule"/>

        <ruleset name="specific_rules">
            <rule>rule1</rule>
            <rule>rule3</rule>
        </ruleset>
        
        <ruleset name="by_class" rulesOfClass="VS::RuleEngine::Rule"/>
    </engine>
});

is_deeply([sort $engine->rules], [qw(rule1 rule2 rule3)]);

my $rule = $engine->_get_rule("rule1");
is($rule->_pkg, "VS::RuleEngine::Rule");

$rule = $engine->_get_rule("rule2");
is_deeply($rule->_args, [ arg1 => 1, arg2 => undef ]);

ok(exists $loader->_ruleset->{all_rules});
is_deeply($loader->_ruleset->{all_rules}, [qw(rule1 rule2)]);

ok(exists $loader->_ruleset->{specific_rules});
is_deeply($loader->_ruleset->{specific_rules}, [qw(rule1 rule3)]);

ok(exists $loader->_ruleset->{by_class});
is_deeply($loader->_ruleset->{by_class}, [qw(rule1 rule2 rule3)]);

# some errors
throws_ok {
    VS::RuleEngine::Loader::XML->load_string(q{<engine><ruleset name="ruleset1"/><ruleset name="ruleset1"/></engine>});
} qr/Ruleset 'ruleset1' is already defined/;

throws_ok {
    VS::RuleEngine::Loader::XML->load_string(q{<engine><ruleset name="ruleset1"><rule/></ruleset></engine>});
} qr/Empty 'rule' name/;

throws_ok {
    VS::RuleEngine::Loader::XML->load_string(q{<engine><ruleset name="ruleset1"><rule>foo</rule></ruleset></engine>});
} qr/No rule named 'foo' exists/;

throws_ok {
    VS::RuleEngine::Loader::XML->load_string(q{<engine><ruleset name="ruleset1"><ruleset>foo</ruleset></ruleset></engine>});
} qr/No ruleset named 'foo' exists/;

throws_ok {
    VS::RuleEngine::Loader::XML->load_string(q{<engine><ruleset name="ruleset1"><foo>bar</foo></ruleset></engine>});
} qr/Expected rule or ruleset element but got 'foo'/;