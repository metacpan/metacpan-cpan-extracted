#!/usr/bin/env perl

# Test handling of rules and their values with different kinds
# params.

use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 2;
use Data::Dumper;
use IO::Handle;

subtest 'array and hash refs work as boolexpr values' => sub {
    plan tests => 9;

    class URT::Item {
        id_by => [qw/name group/],
        has => [
            name    => { is => "String" },
            foo     => { is => "String", is_optional => 1 },
            fh      => { is => "IO::Handle", is_optional => 1 },
            scores  => { is => 'ARRAY' },
            things  => { is => 'HASH' },
            relateds => { is => 'URT::Related', reverse_as => 'item', is_many => 1 },
            related_ids => { via => 'relateds', to => 'id', is_many => 1 },
        ]
    };

    class URT::Related {
        has => {
            item => { is => 'URT::Item', id_by => 'item_id' },
        }
    };

    my $scores = [1,2,3];
    my $things = {'one' => 1, 'two' => 2, 'three' => 3};
    my $related_ids = [1,2,3];

    my $rule = URT::Item->define_boolexpr(name => 'Bob', scores => $scores, things => $things, related_ids => $related_ids);
    ok($rule, 'Created boolexpr');

    is($rule->value_for('name'), 'Bob', 'Value for name is correct');
    is($rule->value_for('scores'), $scores, 'Getting the value for "scores" returns the exact same array as was put in');
    is($rule->value_for('things'), $things, 'Getting the value for "things" returns the exact same hash as was put in');
    is($rule->value_for('related_ids'), $related_ids, 'Getting the value for "related_ids" does not return the exact same array as was put in');

    my $tmpl = UR::BoolExpr::Template->resolve('URT::Item', 'name','scores','things','related_ids');
    ok($tmpl, 'Created BoolExpr template');

    my $rule_from_tmpl = $tmpl->get_rule_for_values('Bob', $scores, $things,$related_ids);
    #ok($rule_from_tmpl, 'Created BoolExpr from that template');

    TODO: {
    local $TODO = "rules created from get_rule_for_values() don't have their hard refs properly saved";
        is($rule_from_tmpl->value_for('scores'), $scores, 'Getting the value for "scores" returns the exact same array as was put in');
        is($rule_from_tmpl->value_for('things'), $things, 'Getting the value for "things" returns the exact same hash as was put in');
        is($rule_from_tmpl->value_for('related_ids'), $related_ids, 'Getting the value for "related_ids" does not return the exact same array as was put in');
    }
};

subtest 'multiple coderefs can be used as values' => sub {
    plan tests => 5;

    # FreezeThaw::copyContents (called by thaw()) couldn't handle a data structure
    # with multiple references to the same coderef

    class URT::ItemWithCoderefs {
        has => [
            code_a => { is => 'CODE' },
            code_b => { is => 'CODE' },
            code_c => { is => 'CODE' },
        ],
    };

    my $the_sub = sub { 1 };
    my $rule = URT::ItemWithCoderefs->define_boolexpr(code_a => $the_sub, code_b => $the_sub, code_c => $the_sub);
    ok($rule, 'Created rule with multiple of the same coderef');
    foreach my $key ( qw( code_a code_b code_c ) ) {
        is($rule->value_for($key), $the_sub, "retrieve coderef for $key");
    }

    my $obj = URT::ItemWithCoderefs->create(code_a => $the_sub, code_b => $the_sub, code_c => $the_sub);
    ok($obj, 'Created object with multiple of the same coderef')
}
