#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 13;
use Data::Dumper;

class URT::Item {
    id_by => [qw/name group/],
    has => [
        name    => { is => "String" },
        group   => { is => "String" },
        parent  => { is => "URT::Item", is_optional => 1, id_by => ['parent_name','parent_group'] },
        foo     => { is => "String", is_optional => 1 },
        bar     => { is => "Number", is_optional => 1 },
        # These are designed to be similar to things stripped out of BoolExpr keys during resolve()
        is_id_only                 => { is => 'Boolean' },
        some_param_key             => { is => 'Text' },
        a_unique_string            => { is => 'Text' },
        clobber__get_serial_number => { is => 'Number'},
        the_change_count           => { is => 'Number' },
    ]
};

class URT::FancyItem {
    is  => 'URT::Item',
    has => [
        feet    => { is => "String" }
    ]
};

class URT::UnrelatedItem {
    id_by => [
        ui_id => { is => 'Integer' },
    ],
    has => [
        name    => { is => "String" },
        group   => { is => "String" },
    ],
};

my $test_obj = URT::Item->create(name => 'blah', group => 'cool', foo => 'foo', bar => 12345);


foreach my $class_name ( qw( URT::Item URT::FancyItem ) ) {
    foreach my $meta_params ( [], [-group_by => ['bar']], [-order => ['bar']], [-limit => 5], [-offset => 5] ) {

        my $meta_params_as_string = _meta_params_as_string($meta_params);
        subtest "class $class_name with meta params $meta_params_as_string" => sub {
            plan tests => 16;

            my $bx = $class_name->define_boolexpr(@$meta_params);
            my $tmpl = $bx->template;
            ok(! $bx->is_id_only, 'Rule with no filters is not is_id_only');
            ok(! $tmpl->is_id_only, 'Rule template with no filters is not is_id_only');
            ok(! $tmpl->is_partial_id, 'Rule template with no filters is not is_partial_id');
            my $is_matches_all = (! $meta_params->[0] or ($meta_params->[0] ne '-limit' and $meta_params->[0] ne '-offset'));
            is($tmpl->matches_all, $is_matches_all, 'Rule template matches_all with no filters');

            $bx = $class_name->define_boolexpr(name => 'blah', @$meta_params);
            $tmpl = $bx->template;
            ok(! $bx->is_id_only, 'Rule with one ID property filter is not is_id_only');
            ok(! $tmpl->is_id_only, 'Rule template with one ID property filter is not is_id_only');
            ok($tmpl->is_partial_id, 'Rule template with one ID property filter is is_partial_id');
            ok(!$tmpl->matches_all, 'Rule template with one ID property filter is not matches_all');

            $bx = $class_name->define_boolexpr(name => 'blah', group => 'foo', @$meta_params);
            $tmpl = $bx->template;
            ok($bx->is_id_only, 'Rule with both ID property filters is is_id_only');
            ok($tmpl->is_id_only, 'Rule template with both ID property filters is is_id_only');
            ok(! $tmpl->is_partial_id, 'Rule template with both ID property filter is not is_partial_id');
            ok(! $tmpl->matches_all, 'Rule template with both ID property filter is not matches_all');

            $bx = $class_name->define_boolexpr(parent_name => '12345', @$meta_params);
            $tmpl = $bx->template;
            ok(! $bx->is_id_only, 'Rule with no ID filters is not is_id_only');
            ok(! $tmpl->is_id_only, 'Rule template with no ID filters is not is_id_only');
            ok(! $tmpl->is_partial_id, 'Rule template with no ID filters is not is_partial_id');
            ok(! $tmpl->matches_all, 'Rule template with no ID filters is not matches_all');
        };
    }
}


foreach my $meta_params ( [], [-group_by => ['group']] ) {
    my $meta_params_as_string = _meta_params_as_string($meta_params);
    subtest "class URT::UnrelatedItem with meta params $meta_params_as_string" => sub {
        plan tests => 13;

        my $bx = URT::UnrelatedItem->define_boolexpr(@$meta_params);
        my $tmpl = $bx->template;
        ok(! $bx->is_id_only, 'Rule with no filters is not is_id_only');
        ok(! $tmpl->is_id_only, 'Rule template with no filters is not is_id_only');
        ok(! $tmpl->is_partial_id, 'Rule template with no filters is not is_partial_id');
        ok($tmpl->matches_all, 'Rule template with no filters is matches_all');

        $bx = URT::UnrelatedItem->define_boolexpr(ui_id => 1, @$meta_params);
        $tmpl = $bx->template;
        ok($tmpl->is_id_only, 'Rule with the single ID param is is_id_only');
        ok(! $tmpl->is_partial_id, 'Rule with the single ID param is not is_partial_id');
        ok(! $tmpl->matches_all, 'Rule with the single ID param is not matches_all');

        $bx = URT::UnrelatedItem->define_boolexpr(ui_id => [2], @$meta_params);
        $tmpl = $bx->template;
        ok($tmpl->is_id_only, 'Rule with the single ID in-clause param is is_id_only');
        ok(! $tmpl->is_partial_id, 'Rule with the single ID in-clause param is not is_partial_id');
        ok(! $tmpl->matches_all, 'Rule with the single ID in-clause param is not matches_all');

        $bx = URT::UnrelatedItem->define_boolexpr(name => 'foo', @$meta_params);
        $tmpl = $bx->template;
        ok(! $tmpl->is_id_only, 'Rule template with no ID filters is not is_id_only');
        ok(! $tmpl->is_partial_id, 'Rule template with no ID filters is not is_partial_id');
        ok(! $tmpl->matches_all, 'Rule template with no ID filters is not matches_all');
    };
}



subtest operators => sub {
    my @tests = (
            # get params                                            property  operator   expected val
        [ [ name => 'blah'],                                        'name',    '=',       'blah' ],
        [ [ name => { operator => '=', value => 'blah'}],           'name',    '=',       'blah' ],
        [ [ 'name =' => 'blah'],                                    'name',    '=',       'blah' ],
        [ [ name => undef],                                         'name',    '=',       undef  ],

        [ [ bar => 1 ],                                             'bar',     '=',       1 ],
        [ [ bar => { operator => '<', value => 1 }],                'bar',     '<',       1 ],

        [ [ name => [ 'bob', 'joe', 'frank' ] ],                    'name',    'in',      ['bob','frank','joe']], # list values are sorted
        [ [ name => { operator => 'not in', value => [1,2,3]} ],    'name',    'not in',  [1,2,3] ],
        [ [ 'name in', => [ 'bob', 'joe', 'frank' ] ],              'name',    'in',      ['bob','frank','joe']],
        [ [ 'name not in' => [ 'bob', 'joe', 'frank' ] ],           'name',    'not in',  ['bob','frank','joe']],
        [ [ name => [ undef ] ],                                    'name',    'in',      [undef] ],
        [ [ name => { operator => 'in', value => [ undef ] } ],     'name',    'in',      [undef] ],
        [ [ 'name in' => [undef] ],                                 'name',    'in',       [undef] ],
        [ [ 'name in' => [ 1, undef]],                              'name',    'in',      [1, undef] ],

        [ [ bar => { operator => 'between', value => [0,3] } ],     'bar',     'between', [0,3] ],
        [ [ bar => { operator => 'not between', value => [0,3] } ], 'bar',     'not between', [0,3] ],
        [ [ 'bar between' => [0,3] ],                               'bar',     'between', [0,3] ],
        [ [ 'bar not between' => [0,3] ],                           'bar',     'not between', [0,3] ],

        [ [ parent => $test_obj ],                                  'parent_name', '=',   'blah' ],
        [ [ parent => $test_obj ],                                  'parent_group','=',   'cool' ],

        [ [ is_id_only => 1 ],                                      'is_id_only', '=', 1 ],
        [ [ a_unique_string => 'hithere'],                          'a_unique_string', '=', 'hithere' ],
        [ [ clobber__get_serial_number => 123],                     'clobber__get_serial_number','=', 123],
        [ [ the_change_count => 456],                               'the_change_count', '=', 456],
    );

    plan tests => (@tests * 3);

    for( my $i = 0; $i < @tests; $i++) {
        my $test = $tests[$i];

        my @rule_params = @{ $test->[0] };

        my $r = URT::Item->define_boolexpr(@rule_params);
        ok($r, "Defined a BoolExpr for test $i");

        my($property, $expected_operator, $expected_value) = @$test[1..3];

        my $got_operator = $r->operator_for($property);
        is($got_operator, $expected_operator, "Operator for $property is '$expected_operator'");

        my $got_value = $r->value_for($property);
        is_deeply($got_value, $expected_value, "Value for $property matched");
    }
};


sub _meta_params_as_string {
    my $params = shift;

    unless ( @$params ) {
        return "[]"
    }

    return sprintf('%s => [ %s ]',
                    $params->[0],
                    ref($params->[1]) eq 'ARRAY'
                        ? join(', ', map { qq('$_') } @{$params->[1]})
                        : $params->[1]
                    );
}
