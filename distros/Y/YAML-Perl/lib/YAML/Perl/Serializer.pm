package YAML::Perl::Serializer;
use strict;
use warnings;

use YAML::Perl::Error;

package YAML::Perl::Error::Serializer;
use YAML::Perl::Error::Marked -base;

package YAML::Perl::Serializer;
use YAML::Perl::Processor -base;

field 'next_layer' => 'emitter';

field 'emitter_class', -init => '"YAML::Perl::Emitter"';
field 'emitter', -init => '$self->create("emitter")';

field 'resolver_class', 'YAML::Perl::Resolver';
field 'resolver', -init => '$self->create("resolver")';

use constant ANCHOR_TEMPLATE => '%03d';

field 'use_encoding';
field 'use_explicit_start' => 1;
field 'use_explicit_end';
field 'use_version';
field 'use_tags';
field 'serialized_nodes' => {};
field 'anchors' => {};
field 'last_anchor_id' => 0;
field 'closed';

sub serialize {
    my $self = shift;
    for my $node (@_) {
        $self->serialize_document($node);
    }
    return ${$self->emitter->writer->stream->buffer};
}

sub open {
    my $self = shift;
    $self->SUPER::open(@_);
    $self->emitter->emit(
        YAML::Perl::Event::StreamStart->new()
    );
    return $self;
}

sub close {
    my $self = shift;
    $self->emitter->emit(
        YAML::Perl::Event::StreamEnd->new()
    );
    $self->SUPER::close(@_);
    return $self;
}

sub serialize_document {
    my $self = shift;
    my $node = shift;
#     if self.closed is None:
#         raise SerializerError("serializer is not opened")
#     elif self.closed:
#         raise SerializerError("serializer is closed")
    $self->emitter->emit(
        YAML::Perl::Event::DocumentStart->new(
            explicit => $self->use_explicit_start,
            version => $self->use_version,
            tags => $self->use_tags,
        )
    );
    $self->anchor_node($node);
    $self->serialize_node($node, undef, undef);
    $self->emitter->emit(
        YAML::Perl::Event::DocumentEnd->new(
            explicit => $self->use_explicit_end
        )
    );
    $self->serialized_nodes({});
    $self->anchors({});
    $self->last_anchor_id(0);
}

sub anchor_node {
    my $self = shift;
    my $node = shift;
    if (exists $self->anchors->{$node}) {
        if (not defined $self->anchors->{$node}) {
            $self->anchors->{$node} = $self->generate_anchor($node);
        }
    }
    else {
        $self->anchors->{$node} = undef;
        if ($node->isa('YAML::Perl::Node::Sequence')) {
            for my $item (@{$node->value}) {
                $self->anchor_node($item);
            }
        }
        elsif ($node->isa('YAML::Perl::Node::Mapping')) {
            for (my $i = 0; $i < @{$node->value}; $i += 2) {
                my $key = $node->value->[$i];
                my $value = $node->value->[$i + 1];
                $self->anchor_node($key);
                $self->anchor_node($value);
            }
        }
    }
}

sub generate_anchor {
    my $self = shift;
    my $node = shift;
    $self->last_anchor_id($self->last_anchor_id + 1);
    return sprintf ANCHOR_TEMPLATE, $self->last_anchor_id;
}

sub serialize_node {
    my $self = shift;
    my $node = shift;
    my $parent = shift;
    my $index = shift;

    my $alias = $self->anchors->{$node};
    if ($self->serialized_nodes->{$node}) {
        $self->emitter->emit(
            YAML::Perl::Event::Alias->new(
                anchor => $alias,
            )
        );
    }
    else {
        $self->serialized_nodes->{$node} = True;
        $self->resolver->descend_resolver($parent, $index);
        if ($node->isa('YAML::Perl::Node::Scalar')) {
            my $detected_tag = $self->resolver->resolve(
                'YAML::Perl::Node::Scalar',
                $node->value,
                [True, False]
            );
            my $default_tag = $self->resolver->resolve(
                'YAML::Perl::Node::Scalar',
                $node->value,
                [False, True]
            );
            my $implicit = [
                (($node->tag || '') eq $detected_tag),
                (($node->tag || '') eq $default_tag),
            ];
            $self->emitter->emit(YAML::Perl::Event::Scalar->new(
                anchor => $alias,
                tag => $node->tag,
                implicit => $implicit,
                value => $node->value,
                style => $node->style,
            ));
        }
        elsif ($node->isa('YAML::Perl::Node::Sequence')) {
            my $implicit = ($node->tag || '') eq $self->resolver->resolve(
                'YAML::Perl::Node::Sequence',
                $node->value,
                True
            );
            $self->emitter->emit(YAML::Perl::Event::SequenceStart->new(
                anchor => $alias,
                tag => $node->tag,
                implicit => $implicit,
                flow_style => $node->flow_style)
            );
            $index = 0;
            for my $item (@{$node->value}) {
                $self->serialize_node($item, $node, $index);
                $index += 1;
            }
            $self->emitter->emit(YAML::Perl::Event::SequenceEnd->new());
        }
        elsif ($node->isa('YAML::Perl::Node::Mapping')) {
            my $implicit = ($node->tag || '') eq $self->resolver->resolve(
                'YAML::Perl::Node::Mapping',
                $node->value,
                True
            );
            $self->emitter->emit(YAML::Perl::Event::MappingStart->new(
                anchor => $alias,
                tag => $node->tag,
                implicit => $implicit,
                flow_style => $node->flow_style
            ));
            for (my $i = 0; $i < @{$node->value}; $i += 2) {
                my $key = $node->value->[$i];
                my $value = $node->value->[$i + 1];
                $self->serialize_node($key, $node, undef);
                $self->serialize_node($value, $node, $key);
            }
            $self->emitter->emit(YAML::Perl::Event::MappingEnd->new());
        }
        $self->resolver->ascend_resolver();
    }
}

1;
