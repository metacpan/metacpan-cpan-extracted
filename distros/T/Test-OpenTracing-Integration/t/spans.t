#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;
use Test::Deep qw/true false/;
use List::Util qw/uniq/;
use Carp qw/croak/;

use OpenTracing::Implementation::Test;

{
    my $tracer = OpenTracing::Implementation::Test->bootstrap_tracer();

    my $scope = $tracer->start_active_span('begin', tags => { a => 1 });
    $tracer->cmp_easy([ { operation_name => 'begin', has_finished => false } ], 'unfinished span');

    my $child = $tracer->start_span('sub', tags => { a => 2 });
    $tracer->cmp_easy(
        [
            { operation_name => 'begin', has_finished => false },
            { operation_name => 'sub',   has_finished => false },
        ],
        'another unfinished span'
    );

    $scope->get_span->add_tag('type' => 'test');
    $child->add_tag('child' => 1);

    $child->finish();
    $scope->close();

    $tracer->cmp_easy(
        [
            { has_finished => true, operation_name => 'begin', tags => { a => 1, type  => 'test' } },
            { has_finished => true, operation_name => 'sub',   tags => { a => 2, child => 1 } },
        ],
        'correct tags in finished spans'
    );
}

{
    my $tracer = OpenTracing::Implementation::Test->bootstrap_tracer();

    my $scope = $tracer->start_active_span('time_test');
    sleep 2;
    $scope->close();
    $tracer->cmp_easy(
        [ { duration => num(2, 1), has_finished => true } ],
        'duration of a finished span'
    );
}

{
    my $tracer = OpenTracing::Implementation::Test->bootstrap_tracer();

    my $scope = $tracer->start_active_span('time_test');
    for ( 1 .. 10 ) {
        $tracer->start_span("span_$_")->finish();
    }
    $scope->close();

    my @spans = $tracer->get_spans_as_struct();
    my $trace_ids = uniq map { $_->{trace_id} } @spans;
    is $trace_ids, 1, 'all spans have the same trace_id'
        or diag explain \@spans;
    my $span_ids = uniq map { $_->{span_id} } @spans;
    is $span_ids, scalar @spans, 'each span has a unique span_id'
        or diag explain \@spans;
}

{
    my $tracer = OpenTracing::Implementation::Test->bootstrap_tracer();

    my $scope1 = $tracer->start_active_span('first');
    my $span1 = $tracer->get_active_span();
    is $span1->get_operation_name, 'first', 'get_active_span returns the only span';

    my $scope2 = $tracer->start_active_span('second');
    my $span2 = $tracer->get_active_span();
    is $span2->get_operation_name, 'second', 'new span is active';
    is $span2->get_parent_span_id, $span1->get_span_id, 'new span is child of previous active span';

    $scope2->close();

    my $restored_span = $tracer->get_active_span();
    is $restored_span->get_span_id, $span1->get_span_id, 'first scope restored after close';

    $scope1->close();
}

{
    my $tracer = OpenTracing::Implementation::Test->bootstrap_tracer();

    my $main_scope = $tracer->start_active_span('root');
    my $c1 = $tracer->start_active_span('child1');
    $tracer->start_span('cc1')->finish();
    $tracer->start_span('cc2')->finish();
    $c1->close();

    my $c2 = $tracer->start_active_span('child2');
    $tracer->start_span('cc3')->finish();
    $tracer->start_span('cc4')->finish();
    $c2->close();

    $main_scope->close();

    $tracer->cmp_easy(
        [
            { operation_name => 'root',   level => 0 },
            { operation_name => 'child1', level => 1 },
            { operation_name => 'cc1',    level => 2 },
            { operation_name => 'cc2',    level => 2 },
            { operation_name => 'child2', level => 1 },
            { operation_name => 'cc3',    level => 2 },
            { operation_name => 'cc4',    level => 2 },
        ],
        'correct levels in nested spans'
    );
}

{
    my $tracer = OpenTracing::Implementation::Test->bootstrap_tracer();

    my $root1 = $tracer->start_active_span('root1');
    $tracer->start_span('child1')->finish();
    $root1->close();

    my $root2 = $tracer->start_active_span('root2');
    $tracer->start_span('child2')->finish();
    $root2->close();

    $tracer->cmp_easy(
        [
            { operation_name => 'root1',  level => 0, has_finished => 1 },
            { operation_name => 'child1', level => 1, has_finished => 1 },
            { operation_name => 'root2',  level => 0, has_finished => 1 },
            { operation_name => 'child2', level => 1, has_finished => 1 },
        ],
        'new root span created after closing first scope'
    );
}

done_testing();
