package UR::Role::PrototypeWithParams;

use strict;
use warnings;

our $VERSION = "0.47"; # UR $VERSION;

# A plain-perl class to represent a role prototype bound to a set of params.
# It exists ephemerally as a class is composing its roles when using this
# syntax:
#
# class The::Class {
#     roles => [ The::Role->create(param => 'value') ],
# };

sub create {
    my($class, %params) = @_;
    unless (exists($params{prototype}) and exists($params{role_params})) {
        Carp::croak('prototype and role_params are required args to create()');
    }
    my $self = {};
    @$self{'prototype', 'role_params'} = delete @params{'prototype','role_params'};
    if (%params) {
        Carp::croak('Unrecognized params to create(): ' . Data::Dumper::Dumper(\%params));
    }

    return bless $self, $class;
}

sub __role__ {
    my $self = shift;
    return $self;
}

sub instantiate_role_instance {
    my($self, $class_name) = @_;
    my %create_args = ( role_name => $self->role_name, class_name => $class_name );
    $create_args{role_params} = $self->role_params if $self->role_params;
    return UR::Role::Instance->create(%create_args);
}


# direct accessors
foreach my $accessor_name ( qw( prototype role_params ) ) {
    my $sub = sub {
        $_[0]->{$accessor_name};
    };
    no strict 'refs';
    *$accessor_name = $sub;
}

# accessors that delegate to the role prototype
foreach my $accessor_name ( qw( role_name methods overloads has requires attributes_have excludes
                                id_by_property_names has_property_names property_data method_names
                                meta_properties_to_compose_into_classes method_modifiers ),
                            UR::Role::Prototype::meta_properties_to_compose_into_classes()
) {
    my $sub = sub {
        shift->{prototype}->$accessor_name(@_);
    };
    no strict 'refs';
    *$accessor_name = $sub;
}

1;

=pod

=head1 NAME

UR::Role::PrototypeWithParams - Binds a set of params to a role

=head1 DESCRIPTION

Objects of this class are returned when calling C<create()> on a role's class.
They exist temporarily as a class is being defined as a means of binding a
set of role params to a L<UR::Role::Prototype> to use in the C<roles> section
of a class description.  See the "Parameterized Roles" section in L<UR::Role>.

=head2 Methods

=over 4

=item create(prototype => $role_proto, role_params => $hashref)

The constructor.  Both arguments are required.

=item __role__()

Returns itself.  Used by the role composition mechanism to trigger autoloading
the role's module when role names are given as strings in a class definition.

=item instantiate_role_instance($class_name)

Return a L<UR::Role::Instance> object.

=back

=head1 SEE ALSO

L<UR::Role>, L<UR::Role::Prototype>, L<UR::Role::Instance>
