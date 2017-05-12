package Zabbix2::API::Template;

use strict;
use warnings;
use 5.010;
use Carp;

use Moo;
extends qw/Zabbix2::API::CRUDE/;

has 'items' => (is => 'ro',
                lazy => 1,
                builder => '_fetch_items');

sub id {
    ## mutator for id
    my ($self, $value) = @_;
    if (defined $value) {
        $self->data->{templateid} = $value;
        return $self->data->{templateid};
    } else {
        return $self->data->{templateid};
    }
}

sub _prefix {
    my (undef, $suffix) = @_;
    if ($suffix) {
        return 'template'.$suffix;
    } else {
        return 'template';
    }
}

sub _extension {
    return (output => 'extend');
}

sub name {
    my $self = shift;
    return $self->data->{host} || '';
}

sub _fetch_items {
    my $self = shift;
    my $items = $self->{root}->fetch('Item', params => { templateids => [ $self->data->{templateid} ] });
    return $items;
}

1;
__END__
=pod

=head1 NAME

Zabbix2::API::Template -- Zabbix template objects

=head1 SYNOPSIS

  TODO write this

=head1 DESCRIPTION

Handles CRUD for Zabbix template objects.

This is a subclass of C<Zabbix2::API::CRUDE>; see there for inherited methods.

=head1 METHODS

=over 4

=item items()

Accessor for the template's items.

=item name()

Accessor for the template's name (the "host" attribute); returns the empty
string if no name is set, for instance if the template has not been created on
the server yet.

=back

=head1 SEE ALSO

L<Zabbix2::API::CRUDE>.

=head1 AUTHOR

Fabrice Gabolde <fga@cpan.org>
Patches to this file (actually most code) from Chris Larsen <clarsen@llnw.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 SFR

This library is free software; you can redistribute it and/or modify it under
the terms of the GPLv3.

=cut
