package Zabbix::API::Template;

use strict;
use warnings;
use 5.010;
use Carp;

use parent qw/Zabbix::API::CRUDE/;

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

sub prefix {

    my (undef, $suffix) = @_;

    if ($suffix) {

        return 'template'.$suffix;

    } else {

        return 'template';

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

sub items {

    ## accessor for items

    my ($self, $value) = @_;

    if (defined $value) {

        die 'Accessor items called as mutator';

    } else {

        my $items = $self->{root}->fetch('Item', params => { templateids => [ $self->data->{templateid} ] });

        $self->{items} = $items;

        return $self->{items};

    }

}

1;
__END__
=pod

=head1 NAME

Zabbix::API::Template -- Zabbix template objects

=head1 SYNOPSIS

  TODO write this

=head1 DESCRIPTION

Handles CRUD for Zabbix template objects.

This is a subclass of C<Zabbix::API::CRUDE>; see there for inherited methods.

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

L<Zabbix::API::CRUDE>.

=head1 AUTHOR

Fabrice Gabolde <fabrice.gabolde@uperto.com>
Patches to this file (actually most code) from Chris Larsen <clarsen@llnw.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 SFR

This library is free software; you can redistribute it and/or modify it under
the terms of the GPLv3.

=cut
