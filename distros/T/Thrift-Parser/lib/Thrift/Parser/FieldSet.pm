package Thrift::Parser::FieldSet;

=head1 NAME

Thrift::Parser::FieldSet - A set of fields in a structure

=cut

use strict;
use warnings;
use Params::Validate qw(validate_with);
use Data::Dumper;
use Scalar::Util qw(blessed);
use base qw(Class::Accessor::Grouped);
__PACKAGE__->mk_group_accessors(simple => qw(fields));

=head1 USAGE

=head2 fields

Returns an array ref of all the fields in this set.

=cut

sub new {
    my $class = shift;
    my %self = validate_with(
        params => shift,
        spec => {
            fields => 1,
        },
    );
    return bless \%self, $class;
}

=head2 named

  my $value = $field_set->named('id'); 

Searches the fields in the set for the field named $name.  Returns the value of that field.

=cut

sub named {
    my ($self, $name) = @_;
    foreach my $field (@{ $self->{fields} }) {
        if ($field->name eq $name) {
            return $field->value;
        }
    }
    return;
}
*field_named = \&named;

=head2 id

  my $value = $field_set->id(2);

Searches the fields in the set for the field with id $id.  Returns the value of that field.

=cut

sub id {
    my ($self, $id) = @_;
    foreach my $field (@{ $self->{fields} }) {
        if ($field->id eq $id) {
            return $field->value;
        }
    }
    return;
}

=head2 ids

Returns an array ref of the ids of this field set.

=cut

sub ids {
    my $self = shift;
    my @ids = sort { $a <=> $b } map { $_->id } @{ $self->{fields} };
    return \@ids;
}

=head2 field_values

Returns an array ref of the values of the fields in the set.

=cut

sub field_values {
    my $self = shift;
    my @values = map { $_->value } @{ $self->{fields} };
    return \@values;
}

=head2 keyed_field_values

Returns a hashref where the keys are the names of the fields and the values are the values of the fields.

=cut

sub keyed_field_values {
    my $self = shift;
    my %hash = map { $_->name => $_->value } @{ $self->{fields} };
    return \%hash;
}

=head2 keyed_field_values_plain

Returns a hashref where the keys are the names of the fields and the values are the plain values of the fields.

=cut

sub keyed_field_values_plain {
    my $self = shift;
    my %hash = map { $_->name => $_->value->value_plain } @{ $self->{fields} };
    return \%hash;
}

=head2 compose 

Used internally by L<Thrift::Parser::Method> and L<Thrift::Parser::Struct>.  Given a list of key/value pairs, returns a FieldSet object informed by the IDL.

=cut

sub compose {
    my ($self_class, $class, %args) = @_;

	if (! $class->idl) {
		die "Requires an IDL";
	}

    if (! $class->idl->can('field_id')) {
        Thrift::Parser::InvalidArgument->throw(
            key => 'class', value => $class, error => "Doesn't support field_id()",
        );
    }

    # Check for missing non-optional fields

    foreach my $field (@{ $class->idl->fields }) {
        my $default_value = $field->default_value;

		# User may pass '_:id' or the name of the field
		my $key = defined $args{ '_' . $field->id } ? '_' . $field->id : $field->name;

        if (defined $default_value && ! defined $args{$key}) {
            $args{$key} = $default_value;
            next;
        }

        if (! defined $default_value && ! defined $args{$key} && ! $field->optional && $class->isa('Thrift::Parser::Type::Struct')) {
            Thrift::Parser::InvalidArgument->throw("Missing value for field '".$field->name."' in $class compose()");
        }
    }

    my @fields;
    foreach my $key (keys %args) {
        # Determine the IDL type of the field
        my $idl_field;
        if (my ($id) = $key =~ m{^_(\d+)$}) {
            $idl_field = $class->idl->field_id($id);
        }
        else {
            $idl_field = $class->idl->field_named($key);
        }
        if (! $idl_field) {
            Thrift::Parser::InvalidArgument->throw(
                error => "Failed to find referenced field '$key' in the $class IDL spec",
                key => $key, value => $args{$key},
            );
        }
        my $type = $idl_field->type;

        # Cast into the new value

        my $type_class;
        if ($type->isa('Thrift::IDL::Type::Custom')) {
            my $type_name = $type->full_name;
            my $referenced_type = $class->idl_doc->object_full_named($type_name);
            if (! $referenced_type) {
                Thrift::Parser::InvalidSpec->throw("Couldn't find definition of custom type '".$type_name."'");
            }
            my $namespace = $referenced_type->{header}->namespace('perl');
            $type_class = join '::', (defined $namespace ? ($namespace) : ()), $type->local_name;
        }
        else {
            $type_class = 'Thrift::Parser::Type::' . $type->name;
        }

        my $value = $type_class->compose_with_idl($type, $args{$key});

        my $field = Thrift::Parser::Field->new({
            id => $idl_field->id,
            value => $value,
            name => $idl_field->name,
        });
        push @fields, $field;
    }

    return $self_class->new({ fields => \@fields });
}

sub write {
    my ($self, $output) = @_;

    $output->writeStructBegin();
    foreach my $field (@{ $self->{fields} }) {
        $field->write($output);
    }
    $output->writeFieldStop();
    $output->writeStructEnd();
}

=head1 COPYRIGHT

Copyright (c) 2009 Eric Waters and XMission LLC (http://www.xmission.com/).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

1;
