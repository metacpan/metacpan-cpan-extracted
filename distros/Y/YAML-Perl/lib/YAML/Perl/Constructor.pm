package YAML::Perl::Constructor;
use strict;
use warnings;

use YAML::Perl::Error;

package YAML::Perl::Error::Constructor;
use YAML::Perl::Error::Marked -base;

package YAML::Perl::Constructor;
use YAML::Perl::Processor -base;

{
    no warnings 'once';
    $YAML::Perl::Constructor::yaml_constructors = {};
    $YAML::Perl::Constructor::yaml_multi_constructors = {};
}

field 'next_layer' => 'composer';

field 'composer_class', -init => '"YAML::Perl::Composer"';
field 'composer', -init => '$self->create("composer")';

field 'yaml_constructors' =>
    -init =>'$YAML::Perl::Constructor::yaml_constructors';
field 'yaml_multi_constructors' =>
    -init =>'$YAML::Perl::Constructor::yaml_multi_constructors';
field 'constructed_objects' => {};
field 'recursive_objects' => {};
field 'state_generators' => [];
field 'deep_construct' => False;

sub construct {
    my $self = shift;
    if (wantarray) {
        my @data = ();
        while ($self->check_data()) {
            push @data, $self->get_data();
        }
        return @data;
    }
    else {
        return $self->check_data() ? $self->get_data() : ();
    }
}

sub check_data {
    my $self = shift;
    return $self->composer->check_node();
}

sub get_data {
    my $self = shift;
    if ($self->composer->check_node()) {
        return $self->construct_document($self->composer->get_node());
    }
    else {
        return ();
    }
}

sub get_single_data {
    # We won't port this. We allow scalar construction of a single node in a
    # multi document stream.
}

sub construct_document {
    my $self = shift;
    my $node = shift;

    my $data = $self->construct_object($node);
    while (@{$self->state_generators}) {
        my $state_generators = $self->state_generators();
        $self->state_generators([]);
        for my $generator (@$state_generators) {
            for my $dummy (@$generator) { }
        }
    }
    $self->constructed_objects({});
    $self->recursive_objects({});
    $self->deep_construct(False);
    return $data;
}

sub construct_object {
    my $self = shift;
    my $node = shift;
    my $deep = @_ ? shift : False;

    my $old_deep;
    if ($deep) {
        $old_deep = $self->deep_construct();
        $self->deep_construct(True);
    }
    if ($self->constructed_objects->{$node}) {
        return $self->constructed_objects->{$node};
    }
    if ($self->recursive_objects->{$node}) {
        throw YAML::Perl::Error::Constructor(
            undef,
            undef,
            "found unconstructable recursive node",
            $node->start_mark
        );
    }
    $self->recursive_objects->{$node} = undef;
    my $constructor = undef;
    my $tag_suffix = undef;
    if ($self->yaml_constructors->{$node->tag || ''}) {
        $constructor = $self->yaml_constructors->{$node->tag};
    }
    else {
        LOOP1: while (1) {
            for my $tag_prefix (keys %{$self->yaml_multi_constructors}) {
                if ($node->tag =~ /^\Q$tag_prefix\E(.*)/) {
                    $tag_suffix = $1;
                    $constructor = $self->yaml_multi_constructors->{$tag_prefix};
                    last LOOP1;
                }
            }
            if ($self->yaml_multi_constructors->{''}) {
                $tag_suffix = $node->tag;
                $constructor = $self->yaml_multi_constructors->{''};
            }
            elsif ($self->yaml_constructors->{''}) {
                $constructor = $self->yaml_constructors->{''};
            }
            elsif ($node->isa('YAML::Perl::Node::Scalar')) {
                $constructor = \ &construct_scalar;
            }
            elsif ($node->isa('YAML::Perl::Node::Sequence')) {
                $constructor = \ &construct_sequence;
            }
            elsif ($node->isa('YAML::Perl::Node::Mapping')) {
                $constructor = \ &construct_mapping;
            }
            last;
        }
    }
    my $data;
    if (not defined $tag_suffix) {
        $data = &$constructor($self, $node);
    }
    else {
        $data = &$constructor($self, $tag_suffix, $node);
    }
#     if (isinstance(data, types.GeneratorType):
#         generator = data
#         data = generator.next()
#         if self.deep_construct:
#             for dummy in generator:
#                 pass
#         else:
#             self.state_generators.append(generator)
    $self->constructed_objects->{$node} = $data;
    delete $self->recursive_objects->{$node};
    if ($deep) {
        $self->deep_construct($old_deep);
    }
    return $data;
}

sub construct_scalar {
    my $self = shift;
    my $node = shift;
    if (not $node->isa('YAML::Perl::Node::Scalar')) {
        throw YAML::Perl::Error::Constructor(
            undef,
            undef,
            "expected a scalar node, but found %s", $node->id,
            $node->start_mark,
        );
    }
    my $scalar = $node->value;
    if (my $tag = $node->tag) {
        if ($tag =~ s/^tag:yaml.org,2002:perl\/scalar://) {
            return bless \ $scalar, $tag;
        }
    }
    return $scalar;
}

sub construct_sequence {
    my $self = shift;
    my $node = shift;
    my $deep = @_ ? shift : False;

    if (not $node->isa('YAML::Perl::Node::Sequence')) {
        throw YAML::Perl::Error::Constructor(
            undef,
            undef,
            "expected a sequence node, but found %s", $node->id,
            $node->start_mark,
        );
    }
    my $sequence = [
        map $self->construct_object($_, $deep), @{$node->value}
    ];
    if (my $tag = $node->tag) {
        if ($tag =~ s/^tag:yaml.org,2002:perl\/array://) {
            bless $sequence, $tag;
        }
    }
    return $sequence;
}

sub construct_mapping {
    my $self = shift;
    my $node = shift;
    my $deep = @_ ? shift : False;

    if (not $node->isa('YAML::Perl::Node::Mapping')) {
        throw YAML::Perl::Error::Constructor(
            undef,
            undef,
            "expected a mapping node, but found %s", $node->id,
            $node->start_mark,
        );
    }
    my $mapping = {};
    for (my $i = 0; $i < @{$node->value}; $i += 2) {
        my $key_node = $node->value->[$i];
        my $value_node = $node->value->[$i + 1];
        my $key = $self->construct_object($key_node, $deep);
#         try:
#             hash(key)
#         except TypeError, exc:
#             raise ConstructorError("while constructing a mapping", node.start_mark,
#                     "found unacceptable key (%s)" % exc, key_node.start_mark)
        my $value = $self->construct_object($value_node, $deep);
        $mapping->{$key} = $value;
    }
    if (my $tag = $node->tag) {
        if ($tag =~ s/^tag:yaml.org,2002:perl\/hash://) {
            bless $mapping, $tag;
        }
    }
    return $mapping;
}

1;
