package Thrift::Parser::Type::Container;

=head1 NAME

Thrift::Parser::Type::Container - Container base class

=head1 DESCRIPTION

This class implements common behavior for L<Thrift::Parser::Type::list>, L<Thrift::Parser::Type::map> and L<Thrift::Parser::Type::set>.

=cut

use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(blessed);
use base qw(Thrift::Parser::Type);
__PACKAGE__->mk_accessors(qw(val_type));

=head1 METHODS

This class inherits from L<Thrift::Parser::Type>; see docs there for inherited methods.

=head2 compose

  $map_class->define(..)->compose({ key => $value, ... });

  $map_class->define(..)->compose([ $key => $value, ... ]);

  $list_set_class->define(..)->compose([ $item, $item ]);

Call L</define> first before using this method.  If map, call with array or hashref.  For set and list, call with arrayref.  Creates a new object in this class.  Throws L<Thrift::Parser::InvalidArgument>.

=cut

sub compose {
    my ($self, $value) = @_;
    my $class;
    if (! ref $self) {
        $class = $self;
        $self = $class->new();
    }
    else {
        $class = ref $self;
    }

    # If compose() has been called on an already existant container, copy myself to a
    # newly blessed object (sans value) so we can inherit the same val/key_type_class/define values
    if (defined $self->{value}) {
        $self = bless { %$self, value => [] }, $class;
    }

    my $val_type = $self->{val_type_class};
    if (! defined $val_type) {
        if ($class->idl) {
            # We should be able to infer the define call for this compose() automatically
            return $class->compose_with_idl($class->idl->type, $value);
        }
        Thrift::Parser::InvalidArgument->throw("Must call define() on $class before compose()");
    }

    if ($self->{val_type_define}) {
        $val_type = $self->{val_type_class}->define(@{ $self->{val_type_define} });
    }

    my $key_type;
    if ($class->can('key_type')) {
        $key_type = $self->{key_type_class};
        if (! defined $key_type) {
            Thrift::Parser::InvalidArgument->throw("Must call define() on $class before compose() for both key and val types");
        }

        if ($self->{key_type_define}) {
            $key_type = $self->{key_type_class}->define(@{ $self->{key_type_define} });
        }
    }

    if (blessed $value) {
        if (! $value->isa($class)) {
            Thrift::Parser::InvalidArgument->throw("$class compose() can't take a value of ".ref($value));
        }
        #print Dumper({ self => $self, new_value => $value });
        foreach my $key (qw(val_type val_type_class val_type_define key_type key_type_class key_type_define)) {
            next unless defined $self->{$key};
            my ($value_a, $value_b) = ($self->{$key}, $value->{$key});
            if ($key =~ m{_define$}) {
                # Deep check of similarity
                if (Dumper($value_a) ne Dumper($value_b)) {
                    Thrift::Parser::InvalidArgument->throw("$class compose() invalid typed object passed; $key expected '".Dumper($value_a)."', got '".Dumper($value_b)."'");
                }
            }
            elsif ($value_a ne $value_b) {
                Thrift::Parser::InvalidArgument->throw("$class compose() invalid typed object passed; $key expected '$value_a', got '$value_b'");
            }
        }
        return $value;
    }

    my @values;
    if ($key_type) {
        if (! ref $value || (ref $value ne 'HASH' && ref $value ne 'ARRAY')) {
            Thrift::Parser::InvalidArgument->throw("Composing a $class requires a HASHREF or ARRAYREF");
        }
        my @args = ( ref $value eq 'HASH' ? %$value : @$value );
        if (int @args % 2 != 0) {
            Thrift::Parser::InvalidArgument->throw("Composing containers with key's requires a hash; I see an odd number of pairs here");
        }
        for (my $i = 0; $i <= $#args; $i += 2) {
            my ($key, $val) = @args[$i .. $i + 1];
            push @values, [
                $key_type->compose($key),
                $val_type->compose($val),
            ];
        }
    }
    else {
        if (! ref $value || ref $value ne 'ARRAY') {
            Thrift::Parser::InvalidArgument->throw("Composing a $class requires an ARRAYREF");
        }
        foreach my $val (@$value) {
            push @values, $val_type->compose($val);
        }
    }

    $self->value(\@values);

    return $self;
}

=head2 define

  my $list = $list_class->define('::string')->compose([ ... ]);

  my $nested_list = $list_class->define('::list' => [ '::string' ])->compose([ ... ]);

  my $map = $map_class->define('::i32', '::string')->compose([ ... ]);

Call define with a list of class names that define the structure of this container.  In the case of map, pass two values, $key_class and $val_class.  For set and list, just $val_class.  If either the key or the value class are themselves containers, the next argument is expected to be an arrayref of arguments for the nested C<define()> call.  Returns a new object which is ready for L</compose> to be called.

=cut

sub define {
    my ($class, @args) = @_;

    my $self = $class->new();

    foreach my $key (grep { $self->can($_) } qw(key_type val_type)) {
        my $type = shift @args;
        if (! defined $type) {
            Thrift::Parser::InvalidArgument->throw("$class define() requires type for '$key'");
        }
        if (ref $type) {
            Thrift::Parser::InvalidArgument->throw("$class define() invalid type $type");
        }
        if ($type =~ m{^::}) {
            $type = 'Thrift::Parser::Type' . $type;
        }
        if (! $type->can('type_id')) {
            Thrift::Parser::InvalidArgument->throw("$type doesn't support type_id()");
        }
        $self->$key( $type->type_id );
        $self->{$key . '_class'} = $type;

        if ($type->can('val_type') && defined $args[0] && ref $args[0] && ref $args[0] eq 'ARRAY') {
            $self->{$key . '_define'} = shift @args;
        }
    }

    if (int @args) {
        Thrift::Parser::InvalidArgument->throw("$class define() unexpected number of args (".int(@args).") left over");
    }

    return $self;
}

sub compose_with_idl {
    my ($class, $type, $value) = @_;

    if (blessed $value && $value->isa($class)) {
        # Thrift::Parser::Unimplemented->throw("TODO: determine if this typed value adheres to the IDL type");
        return $value;
    }

    my @define = $class->_recursive_define_resolve($type);

    return $class->define(@define)->compose($value);
}

sub _recursive_define_resolve {
    my ($class, $type) = @_;

    my @define;
    foreach my $key (grep { $class->can($_) } qw(key_type val_type)) {
        # If the type of the container is a typedef, and we're in a custom class, resolve it via the object's idl
        # TODO: there's no guarantee the first referenced type is a container type; may need to recurse
        if ($type->isa('Thrift::IDL::Type::Custom') && $class->can('idl') && $class->idl->isa('Thrift::IDL::TypeDef')) {
            $type = $class->idl->type;
        }
        next if ! $type->can($key);
        my $idl_type = $type->$key;

        if ($idl_type->isa('Thrift::IDL::Type::Custom')) {
            my $namespace = $idl_type->{header}->namespace('perl');
            push @define, join ('::', (defined $namespace ? ($namespace) : ()), $idl_type->name);
        }
        elsif ($idl_type->can('val_type')) {
            push @define, '::' . $idl_type->name;
            push @define, [ _recursive_define_resolve($class, $idl_type) ];
        }
        else {
            push @define, '::' . $idl_type->name;
        }
    }
    return @define;
}

=head2 keys

Valid only for map types.  Returns a list of the keys.

=cut

sub keys {
    my $self = shift;
    if (! $self->can('key_type')) {
        Thrift::Parser::Exception->throw("Can't call 'keys()' on ".ref($self));
    }
    my @keys;
    foreach my $pair (@{ $self->{value} }) {
        push @keys, $pair->[0];
    }
    return @keys;
}

=head2 values

Returns a list of the values.

=cut

sub values {
    my $self = shift;
    my $is_map = $self->can('key_type') ? 1 : 0;

    my @values;
    foreach my $value (@{ $self->{value} }) {
        push @values, $is_map ? $value->[1] : $value;
    }
    return @values;
}

sub value_plain {
    my ($self) = @_;

    if ($self->can('key_type')) {
        my %hash;
        foreach my $pair (@{ $self->{value} }) {
            my ($key, $value) = @$pair;
            if (! blessed $key) {
                die "Key is not blessed: " . Dumper($key);
            }
            elsif (! blessed $value) {
                die "Value is not blessed: " . Dumper($value);
            }
            $hash{ $key->value_plain } = $value->value_plain;
        }
        return \%hash;
    }
    else {
        my @array;
        foreach my $value (@{ $self->{value} }) {
            push @array, $value->value_plain;
        }
        return \@array;
    }
}

=head2 size

Returns the number of values or key/value pairs (in the case of a map).

=cut

sub size {
    my $self = shift;
    return int @{ $self->{value} };
}

=head2 each

Sets up an iterator over all the elements of this object and returns the next value or key/value pair (as list).  Returns undef or an empty list (in the case of a map).  Does not auto-reset; call L</each_reset> to reset the iterator.

=cut

sub each {
    my $self = shift;
    my $is_map = $self->can('key_type') ? 1 : 0;

    my $idx = $self->{_each_idx};
    $idx = 0 unless defined $idx;

    if ($idx > $#{ $self->{value} }) {
        $self->{_each_idx} = undef;
        return $is_map ? () : undef;
    }

    $self->{_each_idx} = $idx + 1;
    return $is_map ? @{ $self->{value}[$idx] } : $self->{value}[$idx];
}

=head2 each_reset

Resets the L</reset> iterator.

=cut

sub each_reset {
    my $self = shift;
    $self->{_each_idx} = undef;
}

=head2 index

  my $value = $list->index(0);
  my ($key, $value) = $map->index(0);

Returns the value at the index given (zero starting).  Returns a list if a map type.  Returns undef or () if not present.  Throws L<Thrift::Parser::InvalidArgument>.

=cut

sub index {
    my ($self, $idx) = @_;
    Thrift::Parser::InvalidArgument->throw("Pass an index number")
        unless defined $idx && ! ref $idx && $idx =~ m{^\d+$};
    my $is_map = $self->can('key_type') ? 1 : 0;
    return ($is_map ? () : undef) if $idx > $#{ $self->{value} };
    return $is_map ? @{ $self->{value}[$idx] } : $self->{value}[$idx];
}

=head1 COPYRIGHT

Copyright (c) 2009 Eric Waters and XMission LLC (http://www.xmission.com/).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

1;
