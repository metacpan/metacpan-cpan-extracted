#!/usr/bin/env perl

use strict;
use warnings;

use UR;

use Test::More tests => 3;
use Test::Fatal qw(exception);

use_ok('UR::Observer');

subtest 'defaults' => sub {
    plan tests => 4;

    my @has_defaults = UR::Observer->has_defaults;
    ok(@has_defaults > 0, 'got has_defaults');

    my $o = UR::Observer->create(callback => sub {});
    isa_ok($o, 'UR::Observer', '$o');
    my @observer_args = map { $o->$_ } @has_defaults;

    my @register_callback_args;
    {
        no warnings qw(redefine);
        local *UR::Observer::_insert_record_into_all_change_subscriptions = sub {
            my $class = shift;
            my %values;
            @values{qw(subject_class_name aspect subject_id)} = (shift, shift, shift);
            my $list = shift;
            @values{qw(callback note priority id once)} = @$list;
            @register_callback_args = @values{@has_defaults};
        };
        my $oid = UR::Observer->register_callback(callback => sub {});
        ok($oid, 'registered callback');
    }

    is_deeply(\@register_callback_args, \@observer_args, 'register_callback gets the same defaults as creating an observer');
};

subtest 'exceptions' => sub {
    plan tests => 5;

    subtest 'bad subject_class_name' => sub {
        plan tests => 3;

        my @o = UR::Observer->get(subject_class_name => 'Foo');
        is(scalar(@o), 0, 'no observer exists');

        my $exception = exception { UR::Observer->create(callback => sub {}, subject_class_name => 'Foo') };
        ok($exception, 'got an exception');

        @o = UR::Observer->get(subject_class_name => 'Foo');
        is(scalar(@o), 0, 'no observer created');
    };

    subtest 'bad aspect' => sub {
        plan tests => 3;

        my @o = UR::Observer->get(aspect => 'foo');
        is(scalar(@o), 0, 'no observer exists');

        my $exception = exception { UR::Observer->create(callback => sub {}, aspect => 'foo') };
        ok($exception, 'got an exception');

        @o = UR::Observer->get(aspect => 'foo');
        is(scalar(@o), 0, 'no observer created');
    };

    subtest 'extra parameter' => sub {
        plan tests => 3;

        my $id = UR::Object::Type->autogenerate_new_object_id_uuid;

        my @o = UR::Observer->get(id => $id);
        is(scalar(@o), 0, 'no observer exists');

        my $exception = exception { UR::Observer->create(callback => sub {}, id => $id, foobar => 1) };
        ok($exception, 'got an exception');

        @o = UR::Observer->get(id => $id);
        is(scalar(@o), 0, 'no observer created');
    };

    subtest 'missing callback' => sub {
        plan tests => 3;

        my $id = UR::Object::Type->autogenerate_new_object_id_uuid;

        my @o = UR::Observer->get(id => $id);
        is(scalar(@o), 0, 'no observer exists');

        my $exception = exception { UR::Observer->create(id => $id) };
        ok($exception, 'got an exception');

        @o = UR::Observer->get(id => $id);
        is(scalar(@o), 0, 'no observer created');
    };

    subtest 'undef parameters' => sub {
        my @param_names = grep { $_ ne 'id' } UR::Observer->required_params_for_register;
        plan tests => scalar(@param_names) + 1;

        ok(@param_names > 0, 'got some param names');

        for my $param_name (@param_names) {
            my %params = UR::Observer->defaults_for_register_callback;
            $params{$param_name} = undef;
            subtest $param_name => sub {
                plan tests => 3;

                my $id = UR::Object::Type->autogenerate_new_object_id_uuid;

                my @o = UR::Observer->get(id => $id);
                is(scalar(@o), 0, 'no observer exists');

                my $exception = exception { UR::Observer->create(callback => sub {}, %params) };
                ok($exception, 'got an exception');

                @o = UR::Observer->get(id => $id);
                is(scalar(@o), 0, 'no observer created');
            };
        }
    };
};
