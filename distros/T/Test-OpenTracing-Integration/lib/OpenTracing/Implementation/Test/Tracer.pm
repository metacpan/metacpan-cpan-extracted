package OpenTracing::Implementation::Test::Tracer;

our $VERSION = 'v0.102.0';

use Moo;

with 'OpenTracing::Role::Tracer';

use aliased 'OpenTracing::Implementation::Test::Scope';
use aliased 'OpenTracing::Implementation::Test::ScopeManager';
use aliased 'OpenTracing::Implementation::Test::Span';
use aliased 'OpenTracing::Implementation::Test::SpanContext';

use Carp qw/croak/;
use PerlX::Maybe qw/maybe/;
use Scalar::Util qw/blessed/;
use Test::Builder;
use Test::Deep qw/superbagof superhashof cmp_details deep_diag/;
use Tree;
use Types::Standard qw/Str/;

use namespace::clean;

use constant {
    HASH_CARRIER_KEY => 'opentracing_context',
    PREFIX_HTTP      => 'OpenTracing-',
};

has '+scope_manager' => (
    required => 0,
    default => sub { ScopeManager->new },
);

has spans => (
    is      => 'rwp',
    default => sub { [] },
    lazy    => 1,
    clearer => 1,
);

has default_context_item => (
    is      => 'ro',
    isa     => Str,
);

sub register_span {
    my ($self, $span) = @_;
    push @{ $self->spans }, $span;
    return;
}

sub get_spans_as_struct {
    my ($self) = @_;
    return map { $self->to_struct($_) } @{ $self->spans };
}

sub span_tree {
    my ($self) = @_;

    my @roots;
    my %nodes = map { $_->get_span_id() => $self->_tree_node($_) } @{ $self->spans };
    foreach my $span (@{ $self->spans }) {
        my $node      = $nodes{ $span->get_span_id };
        my $parent_id = $span->get_parent_span_id;

        if (defined $parent_id) {
            $nodes{$parent_id}->add_child($node);
        }
        else {
            push @roots, $node;
        }
    }

    return join "\n",
      map { @{ $_->tree2string({ no_attributes => 1 }) } } @roots;
}

sub _tree_node {
    my ($self, $span) = @_;
    my $name   = $span->get_operation_name;
    my $status = $span->has_finished ? $span->duration : '...';
    return Tree->new("$name ($status)");
}

sub to_struct {
    my ($class, $span) = @_;
    my $context = $span->get_context();
    
    my $data = {
        baggage_items       => { $context->get_baggage_items },
        context_item        => $context->context_item,
        has_finished        => !!$span->has_finished(),
        level               => $context->level,
        operation_name      => $span->get_operation_name,
        parent_id           => scalar $span->get_parent_span_id(),
        span_id             => $context->span_id,
        start_time          => $span->start_time(),
        tags                => { $span->get_tags },
        trace_id            => $context->trace_id,
        
        $span->has_finished() ? (  # these die on unfinished spans
            duration        => $span->duration(),
            finish_time     => $span->finish_time(),
        ) : (
            duration        => undef,
            finish_time     => undef,
        ),
    };
    
    return $data
}

sub extract_context_from_hash_reference {
    my ($self, $carrier) = @_;

    my $context = $carrier->{ (HASH_CARRIER_KEY) };
    return $self->_maybe_build_context(%$context);
}

sub inject_context_into_hash_reference  {
    my ($self, $carrier, $context) = @_;

    $carrier->{ (HASH_CARRIER_KEY) } = {
        span_id       => $context->span_id,
        trace_id      => $context->trace_id,
        level         => $context->level,
        context_item  => $context->context_item,
        baggage_items => { $context->get_baggage_items() },
    };
    return $carrier;
}

sub extract_context_from_array_reference {
    my ($self, $carrier) = @_;
    return $self->extract_context_from_hash_reference({@$carrier});
}

sub inject_context_into_array_reference {
    my ($self, $carrier, $context) = @_;

    my %hash_carrier;
    $self->inject_context_into_hash_reference(\%hash_carrier, $context);
    push @$carrier, %hash_carrier;

    return $carrier;
}

sub extract_context_from_http_headers {
    my ($self, $carrier) = @_;

    my $trace_id     = $carrier->header(PREFIX_HTTP . 'Trace-Id');
    my $span_id      = $carrier->header(PREFIX_HTTP . 'Span-Id');
    my $level        = $carrier->header(PREFIX_HTTP . 'Level');
    my $context_item = $carrier->header(PREFIX_HTTP . 'ContextItem');

    my %baggage = map { _decode_baggage_header($_) }
        $carrier->header( PREFIX_HTTP . 'Baggage' );

    return $self->_maybe_build_context(
        trace_id      => $trace_id,
        span_id       => $span_id,
        level         => $level,
        context_item  => $context_item,
        baggage_items => \%baggage,
    );
}

sub inject_context_into_http_headers  {
    my ($self, $carrier, $context) = @_;
    
    $carrier->header(
        PREFIX_HTTP . 'Span-Id'     => $context->span_id,
        PREFIX_HTTP . 'Trace-Id'    => $context->trace_id,
        PREFIX_HTTP . 'Level'       => $context->level,
        PREFIX_HTTP . 'ContextItem' => $context->context_item,
    );

    my %baggage = $context->get_baggage_items();
    while (my ($name, $val) = each %baggage) {
        my $header_field = PREFIX_HTTP . 'Baggage';
        my $header_value = _encode_baggage_header($name, $val);
        $carrier->push_header($header_field => $header_value);
    }

    return $carrier;
}

sub _encode_baggage_header {
    my ($name, $val) = @_;

    foreach ($name, $val) {
        s/\\/\\\\/g;
        s/=/\\=/g;
    }
    return "$name=$val";
}

sub _decode_baggage_header {
    my ($header_value) = @_;
    
    my ($name, $val) = split /(?: \\ \\ )* [^\\] \K = /x, $header_value, 2;
    foreach ($name, $val) {
        s/\\\\/\\/g;
        s/\\=/=/g;
    }
    return ($name, $val);
}


sub _maybe_build_context {
    my ($self, %args) = @_;
    my $trace_id      = delete $args{trace_id};
    my $span_id       = delete $args{span_id};
    my $baggage_items = delete $args{baggage_items} // {};
    return unless defined $trace_id and defined $span_id;

    my %context_args = (
        maybe level        => $args{level},
        maybe context_item => $args{context_item},
    );
    my $context = $self->build_context(%context_args)
                       ->with_trace_id($trace_id)
                       ->with_span_id($span_id)
                       ->with_baggage_items(%$baggage_items);
    return $context;
}


sub build_span {
    my ($self, %opts) = @_;

    my $child_of = $opts{child_of};
    my $context  = $opts{context};
    $context = $context->with_next_level if defined $child_of;

    my $span = Span->new(
        operation_name => $opts{operation_name},
        maybe child_of => $child_of,
        context        => $context,
        start_time     => $opts{start_time} // time,
        tags           => $opts{tags} // {},
    );
    $self->register_span($span);

    return $span
}

sub build_context {
    my ($self, %opts) = @_;
    my $context_item = delete $opts{ context_item }
    || $self->default_context_item;

    return SpanContext->new(
        %opts,
        context_item => $context_item,
    );
}

sub cmp_deeply {
    my ($self, $exp, $test_name) = @_;
    my $test = Test::Builder->new;

    my @spans = $self->get_spans_as_struct;
    my ($ok, $stack) = cmp_details(\@spans, $exp);
    if (not $test->ok($ok, $test_name)) {
        $test->diag(deep_diag($stack));
        $test->diag($test->explain(\@spans));
    }
    return $ok;
}

sub cmp_easy {
    my ($self, $exp, $test_name) = @_;
    $exp = superbagof(map { superhashof($_) } @$exp);
    return $self->cmp_deeply($exp, $test_name);
}

1;

__END__

=pod





=head1 NAME

OpenTracing::Implementation::Test::Tracer - OpenTracing Test for Tracer



=head1 DESCRIPTION

This tracer keeps track of created spans by itself, using an internal structure.
It can be used with L<Test::Builder> tests to check the correctness of OpenTracing
utilites or to easily inspect your instrumentation.



=head1 INSTANCE METHODS

=head2 C<get_spans_as_struct>

Returns a list of hashes representing all spans, including information from
SpanContexts. Example structure:

  (
    {
      operation_name => 'begin',
      span_id        => '7a7da90',
      trace_id       => 'cacbd7a',
      level          => 0,
      parent_id      => undef,
      has_finished   => '',
      start_time     => 1592863360.000000,
      finish_time    => undef,
      duration       => undef,
      baggage_items  => {},
      tags           => { a => 1 },
    },
    {
      operation_name => 'sub',
      span_id        => 'e0be9cc',
      trace_id       => 'cacbd7a'
      level          => 1,
      parent_id      => '7a7da90',
      has_finished   => 1,
      start_time     => 1592863360.000000,
      finish_time    => 1592863360.811969,
      duration       => 0.811956882476807,
      baggage_items  => {},
      tags           => { a => 2 },
    };
  )



=head2 C<span_tree>

Return a string representation of span relationships.



=head2 C<cmp_deeply>

    $tracer->cmp_deeply $all_expected, $test_message;

This L<Test::Builder>-enabled test method, will emit a single test with
C<$test_message>. The test will compare current saved spans (same as returned by
L<get_spans_as_struct>) with C<$all_expected> using C<cmp_deeply> from
L<Test::Deep>.



=head2 C<cmp_easy>

    $tracer->cmp_easy $any_expected, $test_message;

Same as L<cmp_deeply> but transforms C<$any_expected> into a I<super bag> of
I<super hashes> before the comparison, so that not all keys need to be specified
and order doesn't matter.



=head2 C<clear_spans>

Removes all saved spans from the tracer, useful for starting fresh before new
test cases.



=head1 AUTHOR

Szymon Nieznanski <snieznanski@perceptyx.com>



=head1 COPYRIGHT AND LICENSE

'Test::OpenTracing::Integration'
is Copyright (C) 2019 .. 2020, Perceptyx Inc

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This package is distributed in the hope that it will be useful, but it is
provided "as is" and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.


=cut
