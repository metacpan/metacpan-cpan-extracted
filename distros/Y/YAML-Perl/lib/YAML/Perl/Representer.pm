package YAML::Perl::Representer;
use strict;
use warnings;
use overload();

use YAML::Perl::Error;
use YAML::Perl::Nodes;

package YAML::Perl::Error::Representer;
use YAML::Perl::Error::Marked -base;

package YAML::Perl::Representer;
use YAML::Perl::Processor -base;

field 'next_layer' => 'serializer';

field 'serializer_class', -init => '"YAML::Perl::Serializer"';
field 'serializer', -init => '$self->create("serializer")';

field 'default_style';
field 'default_flow_style';
field 'represented_objects' => {};
field 'object_keeper' => [];
field 'alias_key';

sub represent {
    my $self = shift;
    for my $data (@_) {
        $self->represent_document($data);
    }
    return ${$self->serializer->emitter->writer->stream->buffer};
}

sub represent_document {
    my $self = shift;
    my $data = shift;
    my $node = $self->represent_data($data);
    $self->serializer->serialize_document($node);
    $self->represented_objects({});
    $self->object_keeper([]);
    $self->alias_key(undef);
}

sub get_classobj_bases {
    die "get_classobj_bases";
}

sub represent_data {
    my $self = shift;
    my $data = shift;

    if ($self->ignore_aliases($data)) {
        $self->alias_key(undef);
    }
    else {
        $self->alias_key("$data"); # id(data)
    }

    my $node;
    if (defined $self->alias_key) {
        if ($self->represented_objects->{$self->alias_key}) {
            $node = $self->represented_objects->{$self->alias_key};
            #if node is None:
            #    raise RepresenterError("recursive objects are not allowed: %r" % data)
            return $node;
        }
        #self.represented_objects[alias_key] = None
        push @{$self->object_keeper}, $data;
    }
#     data_types = type(data).__mro__
#     if type(data) is types.InstanceType:
#         data_types = self.get_classobj_bases(data.__class__)+list(data_types)
#     if data_types[0] in self.yaml_representers:
#         node = self.yaml_representers[data_types[0]](self, data)
#     else:
#         for data_type in data_types:
#             if data_type in self.yaml_multi_representers:
#                 node = self.yaml_multi_representers[data_type](self, data)
#                 break
#         else:
#             if None in self.yaml_multi_representers:
#                 node = self.yaml_multi_representers[None](self, data)
#             elif None in self.yaml_representers:
#                 node = self.yaml_representers[None](self, data)
#             else:
#                 node = ScalarNode(None, unicode(data))
#     #if alias_key is not None:
#     #    self.represented_objects[alias_key] = node

    if (not ref($data) or overload::Method($data, '""')) {
        return $self->represent_scalar(undef, $data);
    }
    my ($class, $type, $id) = node_info($data);
    if ($type eq 'ARRAY') {
        my $tag = $class
        ? "tag:yaml.org,2002:perl/array:$class"
        : undef;
        $node = $self->represent_sequence($tag, $data);
    }
    elsif ($type eq 'HASH') {
        my $tag = $class
        ? "tag:yaml.org,2002:perl/hash:$class"
        : undef;
        $node = $self->represent_mapping($tag, $data);
    }
    elsif ($type eq 'SCALAR') {
        my $tag = $class
        ? "tag:yaml.org,2002:perl/scalar:$class"
        : undef;
        $node = $self->represent_scalar($tag, $data);
    }
    else {
        die "can't represent '$data' yet...";
    }
    return $node;
}

sub represent_scalar {
    my $self = shift;
    my $tag = shift;
    my $value = shift;
    my $style = @_ ? shift : undef;
    if ($tag) {
        #tag:yaml.org,2002:perl/hash:Baz
        $value = $$value;
    }
    if (not defined $style) {
        $style = $self->default_style;
    }
    my $node = YAML::Perl::Node::Scalar->new(
        tag => $tag,
        value => $value,
        style => $style,
    );
    if (defined $self->alias_key) {
        $self->represented_objects->{$self->alias_key} = $node;
    }
    return $node;
}

sub represent_sequence {
    my $self = shift;
    my $tag = shift;
    my $sequence = shift;
    my $flow_style = @_ ? shift : undef;

    my $value = [];
    my $node = YAML::Perl::Node::Sequence->new(
        tag => $tag,
        value => $value,
        defined($flow_style)
        ? (flow_style => $flow_style) : (),
    );
    if (defined $self->alias_key) {
        $self->represented_objects->{$self->alias_key} = $node;
    }
    my $best_style = False;     # NOTE differs from PyYaml
    for my $item (@$sequence) {
        my $node_item = $self->represent_data($item);
        if (not $node_item->isa('YAML::Perl::Node::Scalar') and
            not $node_item->style
        ) {
            $best_style = False;
        }
        push @$value, $node_item;
    }
    if (not defined $flow_style) {
        if (defined $self->default_flow_style) {
            $node->flow_style($self->default_flow_style);
        }
        else {
            $node->flow_style($best_style);
        }
    }
    return $node;
}

sub represent_mapping {
    my $self = shift;
    my $tag = shift;
    my $mapping = shift;
    my $flow_style = @_ ? shift : undef;

    my $value = [];
    my $node = YAML::Perl::Node::Mapping->new(
        tag => $tag,
        value => $value,
        defined($flow_style)
        ? (flow_style => $flow_style) : (),
    );
    if (defined $self->alias_key) {
        $self->represented_objects->{$self->alias_key} = $node;
    }
    my $best_style = False;     # NOTE differs from PyYaml
#     if hasattr(mapping, 'items'):
#         mapping = mapping.items()
#         mapping.sort()
    for my $item_key (sort keys %$mapping) {
        my $item_value = $mapping->{$item_key};
        my $node_key = $self->represent_data($item_key);
        my $node_value = $self->represent_data($item_value);
        if (not (
            $node_key->isa('YAML::Perl::Node::Scalar') and
            not $node_key->style
        )) {
            $best_style = False;
        }
        if (not (
            $node_value->isa('YAML::Perl::Node::Scalar') and
            not $node_value->style
        )) {
            $best_style = False;
        }
        push @$value, $node_key, $node_value;
    }
    if (not defined $flow_style) {
        if (defined $self->default_flow_style) {
            $node->flow_style($self->default_flow_style);
        }
        else {
            $node->flow_style($best_style);
        }
    }
    return $node;
}

sub ignore_aliases {
    my $self = shift;
    my $data = shift;
    return False;
}

1;
