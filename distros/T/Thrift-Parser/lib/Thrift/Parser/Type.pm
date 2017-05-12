package Thrift::Parser::Type;

=head1 NAME

Thrift::Parser::Type - Base clase for OO types

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use base qw(Class::Data::Accessor Class::Accessor);
__PACKAGE__->mk_accessors(qw(value));
__PACKAGE__->mk_classaccessors(qw(idl name idl_doc));
use Class::ISA;
use Scalar::Util qw(blessed);
use Carp;

=head1 METHODS

=head2 idl

Returns a reference to the L<Thrift::IDL::Type> that informed the creation of this class.

=head2 idl_doc

Returns a reference to the L<Thrift::IDL> object that this was formed from.

=head2 name

Returns the simple name of the type.

=head2 value

Returns the internal representation of the value of this object.

=head2 defined

Boolean; is a value defined for this object.

=cut

sub defined {
    my $self = shift;
    return defined $self->value ? 1 : 0;
}

=head2 compose

  my $object = $subclass->compose(..);

Returns a new object in the class/subclass namespace with the value given.  Generally you may pass a simple perl variable or another object in this same class to create the new object.  Throws L<Thrift::Parser::InvalidArgument> or L<Thrift::Parser::InvalidTypedValue>.  See subclass documentation for more specifics.

=cut

sub compose {
    my ($class, $value) = @_;
    if (blessed $value) {
        if (! $value->isa($class)) {
            Thrift::Parser::InvalidArgument->throw("$class compose() can't take a value of ".ref($value));
        }
        return $value;
    }
    Thrift::Parser::InvalidTypedValue->throw("Value '$value' is not a plain scalar") if defined $value && ref $value;
    return $class->new({ value => $value });
}

=head2 compose_with_idl

Used internally.  Overridden for complex type classes that require the IDL to inform their creation and schema (mainly L<Thrift::Parser::Type::Container>).

=cut

sub compose_with_idl {
    my ($class, $type) = (shift, shift);
    return $class->compose(@_);
}

=head2 read

  my $object = $class->read($protocol);

Implemented in subclasses, this will create new objects from a L<Thrift::Protocol>.

=head2 write 

  $object->write($protocol)

Given a L<Thrift::Protocol> object, will write out this type to the buffer.  Overridden in all most subclasses.

=cut

sub write {
    my ($self, $output) = @_;
    my $class = ref $self;

    # Attempt to do a generic writeType call (where 'Type' is found from the type id)
    if (my $type_id = $class->type_id) {
        my $method = Thrift::Parser::Types->write_method($type_id);
        if ($output->can($method)) {
            $output->$method($self->value);
            return;
        }
    }

    Thrift::Parser::NotImplemented->throw($class . "->write() hasn't been overridden yet");
}

=head2 equal_to

  if ($object_a->equal_to($object_b)) { ... }

Performs an equality test between two blessed objects.  You may also call with a non-blessed reference (a perl scalar, for instance), which will be passed to C<compose()> to be formed into a proper object before the comparison is run.  Throws L<Thrift::Parser::InvalidArgument>.

=cut

sub equal_to {
    my ($self, $value) = @_;
    my $class = ref $self;

    if (! blessed $value) {
        $value = $class->compose($value);
    }
    elsif (! $value->isa($class)) {
        Thrift::Parser::InvalidArgument->throw("equal_to() must be called with the same type of object on both sides ($class)");
    }

    return $class->values_equal($self->value, $value->value);
}

=head2 values_equal

Used internally for the L</equal_to> call.

=cut

sub values_equal {
    my ($class, $value_a, $value_b) = @_;
    Thrift::Parser::NotImplemented->throw($class . "->values_equal() hasn't been overridden yet");
}

=head2 value_name

Implemented by the specific type.

=cut

sub value_name { croak "Not implemented in subclass" }

=head2 value_plain

=cut

sub value_plain { croak "Not implemented in subclass" }

=head2 type_id

Returns the L<Thrift> type id.  Overridden in subclasses.  Throws L<Thrift::Parser::Exception>.

=cut

sub type_id {
    my ($self) = @_;
    my $class = ref $self ? ref $self : $self;

    # Find the base type ('i32', 'string', 'Struct')
    my $base_type;
    foreach my $test_class (Class::ISA::self_and_super_path( $class )) {
        if ($test_class =~ m{^Thrift::Parser::Type::(.+)$}) {
            $base_type = $1;
            last;
        }
    }
    if (! $base_type) {
        Thrift::Parser::Exception->throw("Couldn't resolve '$class' to a basic type class");
    }

    # Lookup the value
    my $id = Thrift::Parser::Types->to_id($base_type);
    if (! defined $id) {
        Thrift::Parser::Exception->throw("Couldn't resolve base type '$base_type' to an id");
    }
    return $id;
}

sub mk_value_passthrough_methods {
    my ($class, @methods) = @_;

    foreach my $method (@methods) {
        my $full_class = $class . '::' . $method;
        no strict 'refs';
        *{ $full_class } = sub {
            my $self = shift;
            return $self->value->$method(@_);
        };
    }
}

=head2 docs_as_pod

Returns a POD formatted string that documents a derived class.

=cut

sub docs_as_pod {
    my ($class, $base_class) = @_;

    my $idl = $class->idl;
    my $name = $class->name;
    
    my ($synopsis, $usage, $arguments);

    my $description = "This is an auto-generated subclass of L<$base_class>; see the docs for that module for inherited methods.  Check the L</USAGE> below for details on the auto-generated methods within this class.\n";

    my $is_method = $base_class eq 'Thrift::Parser::Method' ? 1 : 0;
    my $is_struct = ($base_class eq 'Thrift::Parser::Method' || $base_class eq 'Thrift::Parser::Type::Struct' || $base_class eq 'Thrift::Parser::Type::Exception') ? 1 : 0;
    my $usage_items;

    if ($is_struct) {
        my @usage_items;
        foreach my $field (@{ $class->idl->fields }) {
            my $type = $field->type;
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
            $arguments .= '      ' . $field->name . " => $type_class\->compose(...),\n";
            push @usage_items, '=item I<' . $field->name . "> (type: L<$type_class>)";
        }
        chomp $arguments; # trailing \n
        $usage_items = join "\n\n", @usage_items;
    }

    if ($is_method) {
        $usage = <<EOF;
 =head2 compose_message_call

  my \$message = $class\->compose_message_call(...);

Call with a list of key/value pairs.  The accepted pairs are as follows:

 =over

$usage_items

 =back

The value can either be an object that's strictly typed or simple Perl data structure that is a permissable argument to the C<compose()> call of the given L<Thrift::Parser::Type>.

EOF
        $synopsis = <<EOF;
  # Create a new Method object
  my \$message = $class\->compose_message_call(
$arguments
  );

  # Create a return value from this method
  my \$return = $class\->return_class->compose(...);
EOF
    }
    elsif ($is_struct) {
        $usage = <<EOF;
 =head2 compose

  my \$struct = $class\->compose(...);

Call with a list of key/value pairs.  The accepted pairs are as follows:

 =over

$usage_items

 =back

The value can either be an object that's strictly typed or simple Perl data structure that is a permissable argument to the C<compose()> call of the given L<Thrift::Parser::Type>.

EOF
        $synopsis = <<EOF;
  # Create a new struct object
  my \$struct = $class\->compose(
$arguments
  );
EOF

    }
    else {
        $usage = <<EOF;
EOF
        $synopsis = <<EOF;
  # Create a new Type object
  my \$object = $class\->compose(\$value);
EOF
    }

    my $pod = <<EOF;
 =pod

 =head1 NAME

$class - An auto-generated subclass of $base_class

 =head1 SYNOPSIS

$synopsis

 =head1 DESCRIPTION

$description

 =head1 USAGE

$usage

 =head1 SEE ALSO

L<$base_class>

EOF

    $pod =~ s{^ =}{=}gms;

    return $pod;
}

=head1 COPYRIGHT

Copyright (c) 2009 Eric Waters and XMission LLC (http://www.xmission.com/).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

1;
