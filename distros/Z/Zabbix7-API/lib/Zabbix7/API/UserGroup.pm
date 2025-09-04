package Zabbix7::API::UserGroup;

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Moo;
extends qw/Zabbix7::API::CRUDE/;

use Zabbix7::API::User;

has 'users' => (is => 'ro',
                lazy => 1,
                builder => '_fetch_users');

sub id {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->data->{usrgrpid} = $value;
        Log::Any->get_logger->debug("Set usrgrpid: $value for usergroup");
        return $self->data->{usrgrpid};
    }
    my $id = $self->data->{usrgrpid};
    Log::Any->get_logger->debug("Retrieved usrgrpid for usergroup: " . ($id // 'none'));
    return $id;
}

sub _readonly_properties {
    return {
        usrgrpid => 1,
        gui_access => 1, # Added for Zabbix 7.0 (read-only)
        users_status => 1, # Added for Zabbix 7.0 (read-only)
    };
}

sub _prefix {
    my (undef, $suffix) = @_;
    if ($suffix and $suffix =~ m/ids?/) {
        return 'usrgrp' . $suffix;
    } elsif ($suffix) {
        return 'usergroup' . $suffix;
    }
    return 'usergroup';
}

sub _extension {
    return (
        output => 'extend',
        selectUsers => ['userid', 'alias'], # Added for Zabbix 7.0
        selectTagFilters => 'extend', # Added for Zabbix 7.0
    );
}

sub name {
    my $self = shift;
    my $name = $self->data->{name} || '???';
    Log::Any->get_logger->debug("Retrieved name for usergroup ID: " . ($self->id // 'new') . ": $name");
    return $name;
}

sub _fetch_users {
    my $self = shift;
    my $users = $self->{root}->fetch('User', params => { usrgrpids => [ $self->id ] });
    Log::Any->get_logger->debug("Fetched " . scalar @$users . " users for usergroup ID: " . ($self->id // 'new'));
    return $users;
}

before 'create' => sub {
    my ($self) = @_;
    delete $self->data->{usrgrpid}; # Ensure usrgrpid is not sent
    delete $self->data->{gui_access}; # gui_access is read-only
    delete $self->data->{users_status}; # users_status is read-only
    Log::Any->get_logger->debug("Preparing to create usergroup: " . ($self->data->{name} // 'unknown'));
};

before 'update' => sub {
    my ($self) = @_;
    delete $self->data->{gui_access}; # gui_access is read-only
    delete $self->data->{users_status}; # users_status is read-only
    Log::Any->get_logger->debug("Preparing to update usergroup ID: " . ($self->id // 'new'));
};

1;
__END__
=pod

=head1 NAME

Zabbix7::API::UserGroup -- Zabbix usergroup objects

=head1 SYNOPSIS

  use Zabbix7::API::UserGroup;

  my $group = $zabbix->fetch(...);

  $group->delete;

=head1 DESCRIPTION

Handles CRUD for Zabbix usergroup objects.

This is a very simple subclass of C<Zabbix7::API::CRUDE>.  Only the
required methods are implemented (and in a very simple fashion on top
of that).

=head1 METHODS

=over 4

=item name()

Accessor for the usergroup's name (the "name" attribute); returns the
empty string if no name is set, for instance if the usergroup has not
been created on the server yet.

=item users()

Mutator for the usergroup's users.

=item push()

This method handles extraneous C<< user => Zabbix7::API::User >>
attributes in the users array, transforming them into C<userid>
attributes, and pushing the users to the server if they don't exist
already.  The original user attributes are kept but hidden from the
C<CRUDE> C<push> method, and restored after the C<pull> method is
called.

This means you can put C<Zabbix7::API::User> objects in your data and
the module will Do The Right Thing (assuming you agree with my
definition of the Right Thing).  Users that have been created this way
will not be removed from the server if they are removed from the
graph, however.

Overridden from C<Zabbix7::API::CRUDE>.

=back

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
