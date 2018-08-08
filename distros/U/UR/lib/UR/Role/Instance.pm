package UR::Role::Instance;

use strict;
use warnings;

our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::Role::Instance',
    doc => 'Instance of a role composed into a class',
    id_by => ['role_name','class_name'],
    has => [
        role_name => { is => 'Text', doc => 'ID of the role prototype' },
        role_prototype => { is => 'UR::Role::Prototype', id_by => 'role_name' },
        class_name => { is => 'Test', doc => 'Class this role instance is composed into' },
        class_meta => { is => 'UR::Object::Type', id_by => 'class_name' },
        role_params => { is => 'HASH', doc => 'Parameters used when this role was composed', is_optional => 1 },
    ],
    is_transactional => 0,
);

1;

=pod

=head1 NAME

UR::Role::Instance - Represents a role composed with a class with a set of params

=head1 DESCRIPTION

When a class composes one or more roles, the role names given in the class
description are converted to UR::Role::Instance objects as the class is
constructed.  These are returned by the class' C<roles()> method.

=head2 Methods

=over 4

=item role_name()

Returns the name of the role

=item class_name()

Returns the name of the class composing the role

=item role_params()

Returns a hashref of role params used when the class composed the role

=back

=head1 SEE ALSO

L<UR::Role>, L<UR::Role::Prototype>
