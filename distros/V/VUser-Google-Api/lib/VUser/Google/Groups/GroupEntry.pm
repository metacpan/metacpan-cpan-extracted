package VUser::Google::Groups::GroupEntry;
use warnings;
use strict;

our $VERSION = '0.2.0';

use Moose;

has 'GroupId'         => (is => 'rw', isa => 'Str | Undef');
has 'GroupName'       => (is => 'rw', isa => 'Str | Undef');
has 'Description'     => (is => 'rw', isa => 'Str | Undef');
has 'EmailPermission' => (is => 'rw', isa => 'Str | Undef');

sub as_hash {
    my $self = shift;

    my %hash = (
	groupId         => $self->GroupId,
	groupName       => $self->GroupName,
	description     => $self->Description,
	emailPermission => $self->EmailPermission,
    );

    return %hash;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
