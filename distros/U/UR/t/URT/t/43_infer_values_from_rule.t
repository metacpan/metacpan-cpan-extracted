use strict;
use warnings;
use Test::More;
plan tests => 27;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

UR::DBI->no_commit(1); 

&create_test_data();

my($rule,$value,@values);
my $context = UR::Context->get_current;


$rule = UR::BoolExpr->resolve('URT::43Primary', primary_id => 1, primary_value => 'One');
ok($rule, 'Create rule');
$value = $context->infer_property_value_from_rule('primary_id', $rule);
is($value, 1, 'get a value directly in the rule');


$rule = UR::BoolExpr->resolve('URT::43Primary', rel_id => 1);
ok($rule, 'Create rule');
$value = $context->infer_property_value_from_rule('primary_id', $rule);
is($value, 1, 'infer a direct property with a rule also containing a different direct property');


$value = $context->infer_property_value_from_rule('related_value', $rule);
is($value, 1, 'infer an indirect property with a rule containing a direct property');


$rule = UR::BoolExpr->resolve('URT::43Primary', related_value => '1');
ok($rule, 'Create rule');
$value = $context->infer_property_value_from_rule('rel_id', $rule);
is($value, 1, 'infer a direct linking property with a rule containing an indirect property');


$value = $context->infer_property_value_from_rule('primary_id', $rule);
is($value, 1, 'infer a direct property with a rule containing an indirect property');


$rule = UR::BoolExpr->resolve('URT::43Primary', related_value => '2');
ok($rule, 'Create rule');
@values = $context->infer_property_value_from_rule('primary_id', $rule);
@values = sort @values;
is(scalar(@values), 2, 'inferring a direct property with a rule containing an indirect property matching 2 objects');
is($values[0], 2, 'matched first primary_id');
is($values[1], 3, 'matched second primary_id');


# This ends up returning '3' because there's a Related object with related_id => 3
# though there is no Primary object with a rel_id => 3 
#$rule = UR::BoolExpr->resolve('URT::43Primary', rel_id => 3);
#ok($rule, 'Create rule');
#$value = $context->infer_property_value_from_rule('related_value', $rule);
#is($value, undef, 'infer an indirect property with a rule containing a direct property matching nothing correctly returns undef');


$rule = UR::BoolExpr->resolve('URT::43Related', related_id => 2);
ok($rule, 'Create rule');
@values = $context->infer_property_value_from_rule('primary_values', $rule);
@values = sort {$a cmp $b} @values;
is(scalar(@values), 2, 'infer an indirect, reverse_as property with a rule containing a direct property');
is($values[0], 'Three', 'first inferred value was correct');
is($values[1], 'Two', 'first inferred value was correct');


$rule = UR::BoolExpr->resolve('URT::43Related', primary_values => 'One');
ok($rule, 'Create rule');
$value = $context->infer_property_value_from_rule('related_value', $rule);
is($value, '1', 'infer direct property with a rule containing an indirect, reverse_as property');


$rule = UR::BoolExpr->resolve('URT::43Related', primary_values => 'Two');
ok($rule, 'Create rule');
$value = $context->infer_property_value_from_rule('related_value', $rule);
is($value, '2', 'infer direct property with a rule containing an indirect, reverse_as property');




sub create_test_data {
    ok(URT::43Primary->create(primary_id => 1, primary_value => 'One',rel_id => 1), 'Create test object');
    ok(URT::43Primary->create(primary_id => 2, primary_value => 'Two',rel_id => 2), 'Create test object');
    ok(URT::43Primary->create(primary_id => 3, primary_value => 'Three',rel_id => 2), 'Create test object');
    ok(URT::43Primary->create(primary_id => 4, primary_value => 'Four',rel_id => 4), 'Create test object');

    ok(URT::43Related->create(related_id => 1, related_value => '1'), 'Create test object');
    ok(URT::43Related->create(related_id => 2, related_value => '2'), 'Create test object');
    ok(URT::43Related->create(related_id => 3, related_value => '3'), 'Create test object');
}


