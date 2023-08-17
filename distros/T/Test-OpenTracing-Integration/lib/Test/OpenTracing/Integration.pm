package Test::OpenTracing::Integration;

our $VERSION = 'v0.104.1';

use strict;
use warnings;
use parent 'Exporter';
use Carp qw/croak/;
use OpenTracing::GlobalTracer;

our @EXPORT = qw(
    global_tracer_cmp_deeply
    global_tracer_cmp_easy
    global_tracer_cmp_spans
    reset_spans
);

sub global_tracer_cmp_easy {
    my $tracer = OpenTracing::GlobalTracer->get_global_tracer;
    my $next = $tracer->can('cmp_easy')
        or croak "Not a test implementation, missing 'cmp_easy'";
    unshift @_, $tracer;
    goto $next;
}

sub global_tracer_cmp_deeply {
    my $tracer = OpenTracing::GlobalTracer->get_global_tracer;
    my $next = $tracer->can('cmp_deeply')
        or croak "Not a test implementation, missing 'cmp_deeply'";
    unshift @_, $tracer;
    goto $next;
}

sub global_tracer_cmp_spans {
    my $tracer = OpenTracing::GlobalTracer->get_global_tracer;
    my $next = $tracer->can('cmp_spans')
        or croak "Not a test implementation, missing 'cmp_spans'";
    unshift @_, $tracer;
    goto $next;
}

sub reset_spans {
    my $tracer = OpenTracing::GlobalTracer->get_global_tracer;
    croak "Not a test implementation, missing 'clear_spans'"
        if !$tracer->can('clear_spans');
    return $tracer->clear_spans();
}

1;
