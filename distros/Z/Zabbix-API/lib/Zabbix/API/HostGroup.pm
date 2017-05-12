package Zabbix::API::HostGroup;

use strict;
use warnings;
use 5.010;
use Carp;

use parent qw/Zabbix::API::CRUDE/;

use Zabbix::API::Host;

sub id {

    ## mutator for id

    my ($self, $value) = @_;

    if (defined $value) {

        $self->data->{groupid} = $value;
        return $self->data->{groupid};

    } else {

        return $self->data->{groupid};

    }

}

sub prefix {

    my (undef, $suffix) = @_;

    if ($suffix and $suffix =~ m/ids?/) {

        return 'group'.$suffix;

    } elsif ($suffix) {

        return 'hostgroup'.$suffix;

    } else {

        return 'hostgroup';

    }

}

sub extension {

    return ( output => 'extend' );

}

sub collides {

    my $self = shift;

    return @{$self->{root}->query(method => $self->prefix('.get'),
                                  params => { filter => { name => $self->data->{name} },
                                              $self->extension })};

}

sub name {

    my $self = shift;

    return $self->data->{name} || '';

}

sub hosts {

    my ($self, $value) = @_;

    if (defined $value) {

        die 'Accessor hosts called as mutator';

    } else {

        my $hosts = $self->{root}->fetch('Host', params => { groupids => [ $self->id ] });

        $self->{hosts} = $hosts;

        return $self->{hosts};

    }

}

1;
__END__
=pod

=head1 NAME

Zabbix::API::HostGroup -- Zabbix group objects

=head1 SYNOPSIS

  use Zabbix::API::HostGroup;

  my $group = $zabbix->fetch(...);

  $group->delete;

=head1 DESCRIPTION

Handles CRUD for Zabbix group objects.

This is a very simple subclass of C<Zabbix::API::CRUDE>.  Only the required
methods are implemented (and in a very simple fashion on top of that).

=head1 METHODS

=over 4

=item name()

Accessor for the hostgroup's name (the "name" attribute); returns the empty
string if no name is set, for instance if the hostgroup has not been created on
the server yet.

=item hosts()

Accessor for the hostgroup's hosts.

=back

=head1 SEE ALSO

L<Zabbix::API::CRUDE>.

=head1 AUTHOR

Fabrice Gabolde <fabrice.gabolde@uperto.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 SFR

This library is free software; you can redistribute it and/or modify it under
the terms of the GPLv3.

=cut
