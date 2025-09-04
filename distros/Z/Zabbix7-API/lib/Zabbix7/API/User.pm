package Zabbix7::API::User;

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Moo;
extends qw/Exporter Zabbix7::API::CRUDE/;

use constant {
    USER_TYPE_USER => 1,
    USER_TYPE_ADMIN => 2,
    USER_TYPE_SUPERADMIN => 3,
};

our @EXPORT_OK = qw/
    USER_TYPE_USER
    USER_TYPE_ADMIN
    USER_TYPE_SUPERADMIN
/;

our %EXPORT_TAGS = (
    user_types => [
        qw/USER_TYPE_USER
           USER_TYPE_ADMIN
           USER_TYPE_SUPERADMIN/
    ],
);

sub _readonly_properties {
    return {
        userid => 1,
        attempt_clock => 1,
        attempt_failed => 1,
        attempt_ip => 1,
        roleid => 1, # Added for Zabbix 7.0 (read-only)
    };
}

sub id {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->data->{userid} = $value;
        Log::Any->get_logger->debug("Set userid: $value for user");
        return $self->data->{userid};
    }
    my $id = $self->data->{userid};
    Log::Any->get_logger->debug("Retrieved userid for user: " . ($id // 'none'));
    return $id;
}

sub _prefix {
    my (undef, $suffix) = @_;
    return 'user' . ($suffix // '');
}

sub _extension {
    return (
        output => 'extend',
        selectUsrgrps => ['usrgrpid', 'name'], # Updated for Zabbix 7.0
        selectRole => ['roleid', 'name'], # Added for Zabbix 7.0
    );
}

sub name {
    my $self = shift;
    my $name = $self->data->{alias} || '???';
    Log::Any->get_logger->debug("Retrieved name for user ID: " . ($self->id // 'new') . ": $name");
    return $name;
}

sub _usergroup_or_name_to_usergroup {
    my ($zabbix, $usergroup_or_name) = @_;
    my $usergroup;

    if (ref $usergroup_or_name and eval { $usergroup_or_name->isa('Zabbix7::API::UserGroup') }) {
        $usergroup = $usergroup_or_name;
    } elsif (not ref $usergroup_or_name) {
        $usergroup = $zabbix->fetch_single('UserGroup', params => { filter => { name => $usergroup_or_name } });
        unless ($usergroup) {
            Log::Any->get_logger->error("Usergroup '$usergroup_or_name' not found");
            croak "Parameter to add_to_usergroup or set_usergroups must be a Zabbix7::API::UserGroup object or an existing usergroup name";
        }
    } else {
        Log::Any->get_logger->error("Invalid usergroup parameter");
        croak "Parameter to add_to_usergroup or set_usergroups must be a Zabbix7::API::UserGroup object or an existing usergroup name";
    }

    Log::Any->get_logger->debug("Resolved usergroup: " . $usergroup->name);
    return $usergroup;
}

sub add_to_usergroup {
    my ($self, $usergroup_or_name) = @_;
    croak('Cannot add user without ID to usergroup: needs to be created or fetched')
        unless $self->id;

    my $usergroup = _usergroup_or_name_to_usergroup($self->{root}, $usergroup_or_name);
    $self->{root}->query(
        method => 'usergroup.massadd',
        params => {
            usrgrpids => [ $usergroup->id ],
            userids => [ $self->id ],
        }
    );
    Log::Any->get_logger->debug("Added user ID: " . $self->id . " to usergroup ID: " . $usergroup->id);
    return $self;
}

sub set_usergroups {
    my ($self, @list_of_usergroups_or_names) = @_;
    croak 'User does not exist (yet?) on server'
        unless $self->id; # Replaced 'created' with 'id' check for consistency

    my @list_of_usergroups = map { _usergroup_or_name_to_usergroup($self->{root}, $_) } @list_of_usergroups_or_names;
    $self->{root}->query(
        method => 'user.update',
        params => {
            userid => $self->id,
            usrgrps => [ map { { usrgrpid => $_->id } } @list_of_usergroups ], # Zabbix 7.0 expects array of objects
        }
    );
    Log::Any->get_logger->debug("Set usergroups for user ID: " . $self->id . ", groups: " . join(', ', map { $_->name } @list_of_usergroups));
    return $self;
}

sub set_password {
    my ($self, $password) = @_;
    $self->data->{passwd} = $password;
    Log::Any->get_logger->debug("Set password for user ID: " . ($self->id // 'new'));
    return $self;
}

before 'create' => sub {
    my ($self) = @_;
    delete $self->data->{userid};      # Ensure userid is not sent
    delete $self->data->{roleid};      # roleid is read-only
    Log::Any->get_logger->debug("Preparing to create user: " . ($self->data->{alias} // 'unknown'));
};

before 'update' => sub {
    my ($self) = @_;
    delete $self->data->{roleid}; # roleid is read-only
    Log::Any->get_logger->debug("Preparing to update user ID: " . ($self->id // 'new'));
};

1;
__END__
=pod

=head1 NAME

Zabbix7::API::User -- Zabbix user objects

=head1 SYNOPSIS

  use Zabbix7::API::User;
  # fetch a single user by login ("alias")
  my $user = $zabbix->fetch('User', params => { filter => { alias => 'luser' } })->[0];
  
  # and delete it
  $user->delete;

=head1 DESCRIPTION

Handles CRUD for Zabbix user objects.

This is a subclass of C<Zabbix7::API::CRUDE>; see there for inherited methods.

=head1 METHODS

=over 4

=item usergroups()

Returns an arrayref of the user's usergroups (possibly empty) as
L<Zabbix7::API::UserGroup> objects.

=item add_to_usergroup(USERGROUP_OR_NAME)

Takes a L<Zabbix7::API::UserGroup> instance or a valid usergroup name,
and adds the current user to the group.  Returns C<$self>.

=item set_usergroups(LIST_OF_USERGROUPS_OR_NAMES)

Takes a list of L<Zabbix7::API::UserGroup> instances or valid usergroup
names, and sets the user/usergroup relationship appropriately.
Returns C<$self>.

=item set_password(NEW_PASSWORD)

Sets the user's password.  The modified user is not pushed
automatically to the server.

=item name()

Accessor for the user's name (the "alias" attribute).

=item collides()

This method returns a list of users colliding (i.e. matching) this
one. If there if more than one colliding user found the implementation
can not know on which one to perform updates and will bail out.

=back

=head1 EXPORTS

User types are implemented as constants:

  USER_TYPE_USER
  USER_TYPE_ADMIN
  USER_TYPE_SUPERADMIN

Promote (or demote) users by setting their C<$user->data->{type}>
attribute to one of these.

Nothing is exported by default; you can use the tag C<:user_types> (or
import by name).

=head1 BUGS AND ODDITIES

Apparently when logging in via the web page Zabbix does not care about
the case of your username (e.g. "admin", "Admin" and "ADMIN" will all
work).  I have not tested this for filtering/searching/colliding
users.

=head2 WHERE'S THE remove_from_usergroup METHOD?

L<This|https://support.zabbix.com/browse/ZBX-6124> is where it is.

=head1 SEE ALSO

L<Zabbix7::API::CRUDE>.

=head1 AUTHOR

SCOTTH

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2012, 2013, 2014 SFR
Copyright (C) 2020 Fabrice Gabolde
Copyright (C) 2025 ScottH

This library is free software; you can redistribute it and/or modify it under
the terms of the GPLv3.

=cut
