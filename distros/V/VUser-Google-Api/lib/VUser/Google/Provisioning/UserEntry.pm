package VUser::Google::Provisioning::UserEntry;
use warnings;
use strict;

our $VERSION = '0.2.0';

use Moose;

has 'UserName' => (is => 'rw', isa => 'Str');
has 'GivenName' => (is => 'rw', isa => 'Str');
has 'FamilyName' => (is => 'rw', isa => 'Str');
has 'Password' => (is => 'rw', isa => 'Str');
has 'HashFunctionName' => (is => 'rw', isa => 'Str');
has 'Suspended' => (is => 'rw', isa => 'Bool', default => 0);
has 'Quota' => (is => 'rw', isa => 'Int');
has 'ChangePasswordAtNextLogin' => (is => 'rw', isa => 'Bool', default => 0);
has 'Admin' => (is => 'rw', isa => 'Bool', default => 0);
has 'AgreedToTerms' => (is => 'rw', isa => 'Bool', default => 0);

sub as_hash {
    my $self = shift;

    my %hash = (
	userName   => $self->UserName,
	givenName  => $self->GivenName,
	familyName => $self->FamilyName,
	password   => $self->Password,
	hashFunctionName => $self->HashFunctionName,
	suspended  => $self->Suspended,
	quota      => $self->Quota,
	changePasswordAtNextLogin => $self->ChangePasswordAtNextLogin,
	admin      => $self->Admin,
    );

    return %hash;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
