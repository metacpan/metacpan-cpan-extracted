package Zabbix7::API::Script;

use strict;
use warnings;
use 5.010;
use Carp;

use Moo;
extends qw/Exporter Zabbix7::API::CRUDE/;

use constant {
    SCRIPT_HOSTPERM_READ => 2,
    SCRIPT_HOSTPERM_READWRITE => 3,
};

our @EXPORT_OK = qw/
    SCRIPT_HOSTPERM_READ
    SCRIPT_HOSTPERM_READWRITE
/;

our %EXPORT_TAGS = (
    script_hostperms => [
        qw/SCRIPT_HOSTPERM_READ
           SCRIPT_HOSTPERM_READWRITE/
    ],
);

sub id {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->data->{scriptid} = $value;
        Log::Any->get_logger->debug("Set scriptid: $value for script");
        return $self->data->{scriptid};
    }
    my $id = $self->data->{scriptid};
    Log::Any->get_logger->debug("Retrieved scriptid for script: " . ($id // 'none'));
    return $id;
}

sub _readonly_properties {
    return {
        scriptid => 1,
        user_groupid => 1, # Added for Zabbix 7.0 (read-only)
    };
}

sub _prefix {
    my (undef, $suffix) = @_;
    return 'script' . ($suffix // '');
}

sub _extension {
    return (
        output => 'extend',
        selectGroups => ['groupid', 'name'], # Updated for Zabbix 7.0
        selectHosts => ['hostid', 'host'],   # Updated for Zabbix 7.0
    );
}

sub name {
    my $self = shift;
    my $name = $self->data->{name} || '???';
    Log::Any->get_logger->debug("Retrieved name for script ID: " . ($self->id // 'new') . ": $name");
    return $name;
}

before 'create' => sub {
    my ($self) = @_;
    delete $self->data->{scriptid};     # Ensure scriptid is not sent
    delete $self->data->{user_groupid}; # user_groupid is read-only
    Log::Any->get_logger->debug("Preparing to create script: " . ($self->data->{name} // 'unknown'));
};

before 'update' => sub {
    my ($self) = @_;
    delete $self->data->{user_groupid}; # user_groupid is read-only
    Log::Any->get_logger->debug("Preparing to update script ID: " . ($self->id // 'new'));
};

1;
__END__
=pod

=head1 NAME

Zabbix7::API::Script -- Zabbix script objects

=head1 SYNOPSIS

  use Zabbix7::API::Script;
  
  # Create a script
  use Zabbix7::API::Script qw/:script_hostperms/;
  my $script = Zabbix7::API::Script->new(
      root => $zabbix,
      data => {
          name => 'nmap',
          command => '/usr/bin/nmap {HOST.CONN}',
          host_access => SCRIPT_HOSTPERM_READ,
      },
  );
  $script->create;

=head1 DESCRIPTION

Handles CRUD for Zabbix script objects.

This is a subclass of C<Zabbix7::API::CRUDE>; see there for inherited
methods.

=head1 METHODS

=over 4

=item name()

Mutator for the script's name (the "name" attribute); returns the
empty string if no description is set, for instance if the script has
not been created on the server yet.

=item command()

Mutator for the command to be run by the Zabbix server; returns the
empty string if no command is set, for instance if the script has not
been created on the server yet.

=back

=head1 EXPORTS

Some constants:

  SCRIPT_HOSTPERM_READ
  SCRIPT_HOSTPERM_READWRITE

They are not exported by default, only on request; or you could import
the C<:script_hostperms> tag.

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
