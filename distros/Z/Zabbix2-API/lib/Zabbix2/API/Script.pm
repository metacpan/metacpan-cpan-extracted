package Zabbix2::API::Script;

use strict;
use warnings;
use 5.010;
use Carp;

use Moo;
extends qw/Exporter Zabbix2::API::CRUDE/;

use constant {
    SCRIPT_HOSTPERM_READ => 2,
    SCRIPT_HOSTPERM_READWRITE => 3,
};

our @EXPORT_OK = qw/
SCRIPT_HOSTPERM_READ
SCRIPT_HOSTPERM_READWRITE/;

our %EXPORT_TAGS = (
    script_hostperms => [
        qw/SCRIPT_HOSTPERM_READ
        SCRIPT_HOSTPERM_READWRITE/
    ],
);

sub id {
    ## mutator for id
    my ($self, $value) = @_;
    if (defined $value) {
        $self->data->{scriptid} = $value;
        return $self->data->{scriptid};
    } else {
        return $self->data->{scriptid};
    }
}

sub _readonly_properties {
    return {
        scriptid => 1,
    };
}

sub _prefix {
    my (undef, $suffix) = @_;
    if ($suffix) {
        return 'script'.$suffix;
    } else {
        return 'script';
    }
}

sub _extension {
    return ( output => 'extend',
             selectGroups => 'extend',
             selectHosts => 'extend' );
}

1;
__END__
=pod

=head1 NAME

Zabbix2::API::Script -- Zabbix script objects

=head1 SYNOPSIS

  use Zabbix2::API::Script;
  
  # Create a script
  use Zabbix2::API::Script qw/:script_hostperms/;
  my $script = Zabbix2::API::Script->new(
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

This is a subclass of C<Zabbix2::API::CRUDE>; see there for inherited
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

L<Zabbix2::API::CRUDE>.

=head1 AUTHOR

Ray Link; maintained by Fabrice Gabolde <fga@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 SFR

This library is free software; you can redistribute it and/or modify it under
the terms of the GPLv3.

=cut
