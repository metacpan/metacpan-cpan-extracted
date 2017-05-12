#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";

use UR;
use Test::More tests => 84;

# tests parsing of command-line options

class Cmd::Module::V1 {
    is => 'Command::V1',
    has => [
        a_string => { is => 'String' },
        a_number => { is => 'Number' },
        opt_string => { is => 'String', is_optional => 1 },
        opt_number => { is => 'Number', is_optional => 1 },
        optnumber  => { is => 'Number', is_optional => 1 },
    ],
    has_output => [
        a_output => {
            is => 'Number',
            calculate => q/ return 3 * 2 /,
        },
    ],
};

class Cmd::Module::V2 {
    is => 'Command::V2',
    has => [
        a_string => { is => 'String' },
        a_number => { is => 'Number' },
        opt_string => { is => 'String', is_optional => 1 },
        opt_number => { is => 'Number', is_optional => 1 },
        optnumber  => { is => 'Number', is_optional => 1 },
    ],
    has_output => [
        a_output => {
            is => 'Number',
            calculate => q/ return 3 * 2 /,
        },
    ],
};

# Commands dump errors about missing required properties
# we don't care about those problems
Cmd::Module::V1->dump_error_messages(0);
Cmd::Module::V2->dump_error_messages(0);

foreach my $the_class ( qw( Cmd::Module::V1 Cmd::Module::V2 )) {

    my($class,$params) = $the_class->resolve_class_and_params_for_argv(qw(--a-string blah --a-number 123));
    is($class,$the_class, 'Parse args got correct class');
    is_deeply($params,
              { a_string => 'blah',
                a_number => 123 },
              'Params are correct');
    
    ($class,$params) = $the_class->resolve_class_and_params_for_argv(qw(--a-string=blah --a-number=123));
    is($class,$the_class, 'Parse args got correct class using = in cmdline');
    is_deeply($params,
              { a_string => 'blah',
                a_number => 123 },
              'Params are correct');
   
    my $errors;
    ($class,$params,$errors) = $the_class->resolve_class_and_params_for_argv(qw(--a-string blah));
    is($class,$the_class, 'Parse args got correct class using = in cmdline');
    is_deeply($params,
              { a_string => 'blah'},
              'Params are correct');
    my $r = $class->execute(%$params);
    ok(!$r, "result works");

    ($class,$params) = $the_class->resolve_class_and_params_for_argv(qw(--a-string something=with=equals-signs));
    is($class,$the_class, 'Parse args got correct class where value contains =');
    is_deeply($params,
              { a_string => 'something=with=equals-signs'},
              'Params are correct');
    
    ($class,$params) = $the_class->resolve_class_and_params_for_argv(qw(--a-string=something=with=equals-signs));
    is($class,$the_class, 'Parse args got correct class with = where value contains =');
    is_deeply($params,
              { a_string => 'something=with=equals-signs'},
              'Params are correct');
    
    ($class,$params) = $the_class->resolve_class_and_params_for_argv(qw(--opt-string something=with=equals-signs));
    is($class,$the_class, 'Parse args got correct class with optional param where value contains =');
    is_deeply($params,
              { opt_string => 'something=with=equals-signs'},
              'Params are correct');
    
    ($class,$params) = $the_class->resolve_class_and_params_for_argv(qw(--opt-string=something=with=equals-signs));
    is($class,$the_class, 'Parse args got correct class with optional param = where value contains =');
    is_deeply($params,
              { opt_string => 'something=with=equals-signs'},
              'Params are correct');
    
    
    ($class,$params) = $the_class->resolve_class_and_params_for_argv(qw(--a-string blah --opt-string foo));
    is($class,$the_class, 'Parse args got correct class with is_optional item');
    is_deeply($params,
              { a_string => 'blah',
                opt_string => 'foo' },
              'Params are correct');
    
    ($class,$params) = $the_class->resolve_class_and_params_for_argv(qw(--opt-string foo --opt-number 4));
    is($class,$the_class, 'Parse args got correct class with two is_optional items');
    is_deeply($params,
              { opt_number => 4,
                opt_string => 'foo' },
              'Params are correct');
    
    ($class,$params) = $the_class->resolve_class_and_params_for_argv(qw(--opt-string=foo --opt-number=4));
    is($class,$the_class, 'Parse args got correct class with = and two is_optional items');
    is_deeply($params,
              { opt_number => 4,
                opt_string => 'foo' },
              'Params are correct');
    
    ($class,$params) = $the_class->resolve_class_and_params_for_argv('--opt-string', '', '--opt-number', '');
    is($class,$the_class, 'Parse args got correct class with two optional items with no value');
    is_deeply($params,
              { opt_number => '',
                opt_string => '' },
              'Params are correct');
    
    ($class,$params) = $the_class->resolve_class_and_params_for_argv(qw(--opt-string='' --opt-number=''));
    is($class,$the_class, 'Parse args got correct class with = and two optional items with no value');
    is_deeply($params,
              { opt_number => '',
                opt_string => '' },
              'Params are correct');
    
    ($class,$params) = $the_class->resolve_class_and_params_for_argv(qw(--opt-string="" --opt-number=""));
    is($class,$the_class, 'Parse args got correct class with = and two optional items with no value');
    is_deeply($params,
              { opt_number => '',
                opt_string => '' },
              'Params are correct');
     
    ($class,$params) = $the_class->resolve_class_and_params_for_argv(qw(--opt-number 4));
    is($class,$the_class, 'Parse args got correct class with one optional number');
    is_deeply($params,
              { opt_number => 4},
              'Params are correct');
    
    ($class,$params) = $the_class->resolve_class_and_params_for_argv(qw(--opt-number=4));
    is($class,$the_class, 'Parse args got correct class with = and one optional number');
    is_deeply($params,
              { opt_number => 4},
              'Params are correct');
    
    ($class,$params) = $the_class->resolve_class_and_params_for_argv(qw(--opt-number=-422));
    is($class,$the_class, 'Parse args got correct class with = and one optional negative number');
    is_deeply($params,
              { opt_number => -422},
              'Params are correct');

    ($class,$params) = $the_class->resolve_class_and_params_for_argv(qw(--opt-number -4));
    is($class,$the_class, 'Parse args got correct class with and one optional negative number');
    is_deeply($params,
              { opt_number => -4},
              'Params are correct');

    ($class,$params) = $the_class->resolve_class_and_params_for_argv(qw(--optnumber -422));
    is($class,$the_class, 'Parse args got correct class with and one optional negative number');
    is_deeply($params,
              { optnumber => -422},
              'Params are correct');
    
    ($class,$params) = $the_class->resolve_class_and_params_for_argv(qw(--opt-string -4));
    is($class,$the_class, 'Parse args got correct class with and one optional string where value is a negative number');
    is_deeply($params,
              { opt_string => -4},
              'Params are correct');

    my @args = qw(--a-string=abc --a-number=123);
    my @errors;
    ($class, $params, @errors) = $the_class->resolve_class_and_params_for_argv(@args);
    is($class, $the_class, 'Parse args got correct class with no a_number parameter');
    is(scalar(@errors), 0, "Not specifying a_number doesn't fail");
    is_deeply(
        $params,
        { a_string => 'abc', a_number => 123 },
        'Params are correct'
    );
}
