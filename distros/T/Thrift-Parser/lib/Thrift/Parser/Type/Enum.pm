package Thrift::Parser::Type::Enum;

=head1 NAME

Thrift::Parser::Type::Enum - Enum type

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use base qw(Thrift::Parser::Type);
use Scalar::Util qw(blessed);

=head1 METHODS

This class inherits from L<Thrift::Parser::Type>; see docs there for inherited methods.

=cut

sub type_id {
    return Thrift::Parser::Types->to_id('i32');
}

=head2 compose

Pass either a named element of the enumeration or an index:

  my $value = $enum->compose('PHP');
  my $value = $enum->compose('_4');

As you can see, the index is '_' + digits.  Throws L<Thrift::Parser::InvalidArgument>

=cut

sub compose {
    my ($class, $value) = @_;

    if (blessed $value) {
        if (! $value->isa($class)) {
            Thrift::Parser::InvalidArgument->throw("$class compose() can't take a value of ".ref($value));
        }
        return $value;
    }

    Thrift::Parser::InvalidArgument->throw("'undef' is not valid for $class") if ! defined $value;
    if (my ($id) = $value =~ m{^_(\d+)$}) {
        return $class->new_from_id($id);
    }
    else {
        return $class->new_from_name($value);
    }
}

sub write {
    my ($self, $output) = @_;
    $output->writeI32($self->value);
}

=head2 new_from_id

Same as L</compose> when called with '_' + digit.

=cut

sub new_from_id {
    my ($class, $id) = @_;
    my $name = $class->idl->value_id_name($id);
    Thrift::Parser::InvalidArgument->throw(
            error => "No value found for enum index '$id' in type '".$class->name."'",
            key => 'id', value => $id,
        ) if ! defined $name;
    return $class->new({ value => $id });
}

=head2 new_from_name

Same as L</compose> when called with an element name.

=cut

sub new_from_name {
    my ($class, $name) = @_;
    my $id = $class->idl->value_named($name);
    Thrift::Parser::InvalidArgument->throw(
            error => "No value found for enum index '$name' in type '".$class->name."'",
            key => 'name', value => $name,
        ) if ! defined $id;
    return $class->new({ value => $id });
}

=head2 value_name

  my $object = $enum->compose('PHP');
  $object->value_name == 'PHP';

Returns the name of the element referenced by $self.

=cut

sub value_name {
    my $self = shift;
    return $self->idl->value_id_name($self->value);
}

sub value_plain {
    my $self = shift;
    return $self->value_name;
}

=head1 COPYRIGHT

Copyright (c) 2009 Eric Waters and XMission LLC (http://www.xmission.com/).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

1;
