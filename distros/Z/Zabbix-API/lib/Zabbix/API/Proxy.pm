package Zabbix::API::Proxy;

use strict;
use warnings;
use 5.010;
use Carp;

use parent qw/Zabbix::API::CRUDE/;

sub id {

    ## mutator for id

    my ($self, $value) = @_;

    if (defined $value) {

        $self->data->{proxyid} = $value;
        return $self->data->{proxyid};

    } else {

        return $self->data->{proxyid};

    }

}

sub prefix {

    my (undef, $suffix) = @_;

    if ($suffix) {

        return 'proxy'.$suffix;

    } else {

        return 'proxy';

    }

}

sub extension {

    return ( output => 'extend' );

}

sub collides {

    my $self = shift;

    return @{$self->{root}->query(method => $self->prefix('.get'),
                                  params => { filter => { host => $self->data->{host} },
                                              $self->extension })};

}

sub name {

    my $self = shift;

    return $self->data->{host} || '';

}

sub push {

    die 'Operations that need push (create, update) are not implemented in the current web API.';

}

1;
__END__
=pod

=head1 NAME

Zabbix::API::Proxy -- Zabbix proxy objects

=head1 SYNOPSIS

  use Zabbix::API::Proxy;
  # fetch a proxy by name
  my $proxy = $zabbix->fetch('Proxy', params => { filter => { host => "My Proxy" } })->[0];

  # and update it

  $proxy->data->{status} = 6;
  $proxy->push;

=head1 DESCRIPTION

Handles CRUD for Zabbix proxy objects.

This is a subclass of C<Zabbix::API::CRUDE>; see there for inherited methods.

=head1 METHODS

=over 4

=item name()

Accessor for the proxy's name (the "host" attribute); returns the empty string
if no name is set, for instance if the proxy has not been created on the server
yet.

=back

This is a very simple subclass of C<Zabbix::API::CRUDE>.  Only the required
methods are implemented (and in a very simple fashion on top of that).

=head1 BUGS AND LIMITATIONS

In Zabbix 1.8, the only method available for proxies is to get them. You cannot
add, update or delete proxies.  Thus, the C<push()> method is overloaded for
proxies to throw an exception as soon as it is called.

=head1 SEE ALSO

L<Zabbix::API::CRUDE>.

=head1 AUTHOR

Fabrice Gabolde <fabrice.gabolde@uperto.com>
Patches to this file from Chris Larsen <clarsen@llnw.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 SFR

This library is free software; you can redistribute it and/or modify it under
the terms of the GPLv3.

=cut
