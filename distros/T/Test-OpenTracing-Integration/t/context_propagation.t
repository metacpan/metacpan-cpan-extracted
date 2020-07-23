use Test::Most;
use Test::OpenTracing::Integration;
use OpenTracing::Implementation qw/Test/;
use OpenTracing::GlobalTracer;
use HTTP::Headers;

my @carriers = (
    {
        name      => 'hash reference',
        generator => sub { {} },
    },
    {
        name      => 'array reference',
        generator => sub { [] },
    },
    {
        name      => 'HTTP::Headers',
        generator => sub { HTTP::Headers->new },
    },
);
plan tests => scalar @carriers;
foreach (@carriers) {
    my ($name, $generator) = @$_{qw[ name generator ]};
    subtest $name => sub { test_carrier($generator); };
}

sub test_carrier {
    my ($new_carrier) = @_;
    my $check_context = gen_context_checker($new_carrier);
    reset_spans();

    my $empty_carrier = $new_carrier->();
    ok !defined( $TRACER->extract_context($empty_carrier) ),
        'undef returned when no context can be extracted';
    
    my $root_scope = $TRACER->start_active_span('root_span');
    my $root_span  = $root_scope->get_span();
    $check_context->($root_span->get_context(),
        'extracted context is the same as injected');

    my $active = $new_carrier->();
    $TRACER->inject_context($active);
    cmp_context(
        $TRACER->extract_context($active),
        $TRACER->get_active_span->get_context,
        'active context injected by default'
    );

    my $child = $TRACER->start_active_span('child1');
    $check_context->($child->get_span->get_context(), 'incremented level propagated');
    $child->close();

    my $with_item = $TRACER->start_active_span('child2',
        child_of => $root_span->get_context->with_context_item(12));
    my $item_span = $with_item->get_span();
    $check_context->($with_item->get_span->get_context(), 'context item propagated');
    $with_item->close();

    my $with_baggage = $TRACER->start_active_span('baggage');
    my $baggage_span = $with_baggage->get_span();
    $baggage_span->add_baggage_items(a => 1, b => 2);
    $check_context->($baggage_span->get_context(), 'baggage_items propagated');
    $with_baggage->close();

    my $weird_baggage = $TRACER->start_active_span('weird_baggage');
    my $weird_span = $weird_baggage->get_span();
    $weird_span->add_baggage_items(
        'a=b'           => 1,
        a               => 'x=y',
        escaped         => 'x\=y',
        double_escaped  => 'x\\\=y',
        tripple_escaped => 'x\\\\\=y',
        'stuf===foo'    => '====stuff',
    );
    $check_context->($weird_span->get_context(), 'equality signs in baggage');
    $weird_baggage->close();

    $root_scope->close();

    done_testing();
}

sub gen_context_checker {
    my ($new_carrier) = @_;
    return sub {
        my ($context, $name) = @_;

        my $carrier = $new_carrier->();
        $TRACER->inject_context($carrier, $context);
        my $extracted = $TRACER->extract_context($carrier);
        
        return cmp_context($extracted, $context, $name);
    };
}

sub cmp_context {
    my ($got, $exp, $name) = @_;

    foreach my $context ($got, $exp) {
        $context = {
            span_id       => $context->span_id,
            trace_id      => $context->trace_id,
            level         => $context->level,
            context_item  => $context->context_item,
            baggage_items => { $context->get_baggage_items },
        };
    }
    is_deeply($got, $exp, $name) or explain $got;
}
