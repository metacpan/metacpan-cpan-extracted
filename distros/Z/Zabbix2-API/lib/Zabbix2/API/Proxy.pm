package Zabbix2::API::Proxy;

use strict;
use warnings;
use 5.010;
use Carp;

use Moo;
extends qw/Zabbix2::API::CRUDE/;

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

sub _readonly_properties {
    return {
        proxyid => 1,
        lastaccess => 1,
    };
}

sub _prefix {
    my (undef, $suffix) = @_;
    if ($suffix) {
        return 'proxy'.$suffix;
    } else {
        return 'proxy';
    }
}

sub _extension {
    return (output => 'extend');
}

sub name {
    my $self = shift;
    return $self->data->{host} || '';
}

1;
__END__
=pod

=head1 NAME

Zabbix2::API::Proxy -- Zabbix proxy objects

=head1 SYNOPSIS

  use Zabbix2::API::Proxy;
  # fetch a proxy by name
  my $proxy = $zabbix->fetch_single('Proxy', params => { filter => { host => "My Proxy" } });

=head1 DESCRIPTION

Handles CRUD for Zabbix proxy objects.

This is a subclass of C<Zabbix2::API::CRUDE>; see there for inherited
methods.

=head1 SEE ALSO

L<Zabbix2::API::CRUDE>.

=head1 AUTHOR

Fabrice Gabolde <fga@cpan.org>

Patches to this file's original version from Chris Larsen
<clarsen@llnw.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, 2014 SFR

This library is free software; you can redistribute it and/or modify it under
the terms of the GPLv3.

=cut
