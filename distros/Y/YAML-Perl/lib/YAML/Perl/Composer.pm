# pyyaml/lib/yaml/composer.py
package YAML::Perl::Composer;
use strict;
use warnings;

package YAML::Perl::Composer;
use YAML::Perl::Processor -base;
use YAML::Perl::Events;
use YAML::Perl::Nodes;

field 'next_layer' => 'parser';

field 'parser_class', 'YAML::Perl::Parser';
field 'parser', -init => '$self->create("parser")';

field 'resolver_class', 'YAML::Perl::Resolver';
field 'resolver', -init => '$self->create("resolver")';

field 'anchors' => {};

sub compose {
    my $self = shift;
    if (wantarray) {
        my @nodes = ();
        while ($self->check_node()) {
            push @nodes, $self->get_node();
        }
        return @nodes;
    }
    else {
        return $self->check_node() ? $self->get_node() : ();
    }
}

sub check_node {
    my $self = shift;
    $self->parser->get_event()
        if $self->parser->check_event('YAML::Perl::Event::StreamStart');
    return not($self->parser->check_event('YAML::Perl::Event::StreamEnd'));
}

sub get_node {
    my $self = shift;
    return $self->parser->check_event('YAML::Perl::Event::StreamEnd')
    ? ()
    : $self->compose_document();
}

sub get_single_node {
    # We won't implement this.
    # The PyYaml version throws an error when composing a single node but
    # multiple nodes exist. In Perl we will allow this for iteration.
}

sub compose_document {
    my $self = shift;
    # Drop the DOCUMENT-START event.
    $self->parser->get_event;

    my $node = $self->compose_node(undef, undef);

    # Drop the DOCUMENT-END event.
    $self->parser->get_event();

    $self->anchors({});
    return $node;
}

sub compose_node {
    my $self = shift;
    my $parent = shift;
    my $index = shift;

    my $node;
    if ($self->parser->check_event('YAML::Perl::Event::Alias')) {
        my $event = $self->parser->get_event();
        my $anchor = $event->anchor;
        if (not $self->anchors->{$anchor}) {
            throw YAML::Perl::Error::Composer(
                "found undefined alias $anchor ", $event->start_mark
            );
        }
        return $self->anchors->{$anchor};
    }
    my $event = $self->parser->peek_event();
    my $anchor = $event->anchor;
    if ( defined $anchor && $self->anchors()->{ $anchor } ) {
        throw "found duplicate anchor $anchor" 
            . " first occurance " . $self->anchors()->{ $anchor }
            . " second occurance " . $event->start_mark();
    }
#     $self->resolver->descend_resolver( $parent, $node );
    $node = $self->parser->check_event( 'YAML::Perl::Event::Scalar' ) ? 
            $self->compose_scalar_node( $anchor ) :
        $self->parser->check_event( 'YAML::Perl::Event::SequenceStart' ) ?
            $self->compose_sequence_node( $anchor ) :
        $self->parser->check_event( 'YAML::Perl::Event::MappingStart' ) ?
            $self->compose_mapping_node( $anchor ) : undef;
#     $self->resolver->ascend_resolver();
    return $node;
}

sub compose_scalar_node {
    my $self = shift;
    my $anchor = shift;
    my $event = $self->parser->get_event();
    my $tag = $event->tag;
#     $tag = $self->resolver->resolve(
#         'YAML::Perl::Node::Scalar',
#         $event->value,
#         $event->implicit,
#     ) if not defined $tag or $tag == '!';
    my $node = YAML::Perl::Node::Scalar->new(
        tag => $tag,
        value => $event->value,
        start_mark => $event->start_mark,
        end_mark => $event->end_mark,
        style => $event->style,
    );
    $self->anchors->{$anchor} = $node
      if defined $anchor;
    return $node;
}

sub compose_sequence_node {
    my $self = shift;
    my $anchor = shift;
    my $start_event = $self->parser->get_event();
    my $tag = $start_event->tag;
    if (not $tag or $tag eq '!') {
        $tag = $self->resolver->resolve(
            'YAML::Perl::Node::Sequence', undef, $start_event->implicit
        );
    }
    my $node = YAML::Perl::Node::Sequence-> new(
        tag => $tag,
        value => [],
        start_mark => $start_event->start_mark,
        end_mark => undef,
        flow_style => $start_event->flow_style
    );
    if ($anchor) {
        $self->anchors->{$anchor} = $node;
    }
    my $index = 0;
    while (not $self->parser->check_event('YAML::Perl::Event::SequenceEnd')) {
        push @{$node->value}, $self->compose_node($node, $index);
        $index += 1;
    }
    my $end_event = $self->parser->get_event();
    $node->end_mark($end_event->end_mark);
    return $node;
}

sub compose_mapping_node {
    my $self = shift;
    my $anchor = shift;
    my $start_event = $self->parser->get_event();
    my $tag = $start_event->tag;
    if (not defined $tag or $tag eq '!') {
        $tag = $self->resolver->resolve(
            'YAML::Perl::Node::Mapping',
            undef,
            $start_event->implicit,
        );
    }
    my $node = YAML::Perl::Node::Mapping->new(
        tag => $tag,
        value => [],
        start_mark => $start_event->start_mark,
        end_mark => undef,
        flow_style => $start_event->flow_style,
    );
    if ($anchor) {
        $self->anchors->{$anchor} = $node;
    }
    while (not $self->parser->check_event('YAML::Perl::Event::MappingEnd')) {
        #key_event = self.peek_event()
        my $item_key = $self->compose_node($node, undef);
        #if item_key in node.value:
        #    raise ComposerError("while composing a mapping", start_event.start_mark,
        #            "found duplicate key", key_event.start_mark)
        my $item_value = $self->compose_node($node, $item_key);
        #node.value[item_key] = item_value
        push @{$node->value}, $item_key, $item_value;
    }
    my $end_event = $self->parser->get_event();
    $node->end_mark($end_event->end_mark);
    return $node;
}

1;
