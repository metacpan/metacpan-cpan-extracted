package Thrift::Parser::Type::Struct;

=head1 NAME

Thrift::Parser::Type::Struct - Struct type

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use base qw(Thrift::Parser::Type);
use Scalar::Util qw(blessed);

__PACKAGE__->mk_value_passthrough_methods(qw(named field_named id ids field_values keyed_field_values keyed_field_values_plain));

=head1 METHODS

This class inherits from L<Thrift::Parser::Type>; see docs there for inherited methods.

=head2 value

Returns the L<Thrift::Parser::FieldSet> object which represents the data in this type.

The following methods are available on this class that are passthrough methods to the C<value> object:

  my $field = $object->named('id');
  is equivalent to:
  my $field = $object->value->named('id');

=over

=item I<named>

=item I<id>

=item I<ids>

=item I<field_values>

=item I<keyed_field_values>

=back

=head2 compose

  my $object = $class->compose({ ... });

Call with a hashref of key/value pairs to create a new object.

=cut

sub compose {
    my ($class, $value) = @_;

    if (blessed $value) {
        if (! $value->isa($class)) {
            Thrift::Parser::InvalidArgument->throw("$class compose() can't take a value of ".ref($value));
        }
        return $value;
    }

    my $fieldset = Thrift::Parser::FieldSet->compose($class, %$value);

    return $class->new({ value => $fieldset });
}

sub read { 
    my ($self, $parser, $input, $meta) = @_;

    # Try and find the list of fields that comprise the structure
    my @sub_idl_fields;
    for (1) {
        last unless $meta->{idl}
            && $meta->{idl}{type}->isa('Thrift::IDL::Type::Custom');
        my $struct = $parser->idl->struct_named(
            $meta->{idl}{type}->name
        );
        last unless $struct;
        @sub_idl_fields = @{ $struct->fields };
    }

    $self->value(
        $parser->parse_structure($input, \@sub_idl_fields)
    );
    return $self;
}

sub write {
    my ($self, $output) = @_;
    # FieldSet->write() encompasses all needed behavior
    $self->value->write($output);
}

sub value_plain {
    my $self = shift;
    return $self->keyed_field_values_plain;
}

=head1 COPYRIGHT

Copyright (c) 2009 Eric Waters and XMission LLC (http://www.xmission.com/).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

1;
