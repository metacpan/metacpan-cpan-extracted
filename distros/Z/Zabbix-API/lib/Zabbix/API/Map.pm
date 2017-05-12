package Zabbix::API::Map;

use strict;
use warnings;
use 5.010;
use Carp;

use parent qw/Exporter Zabbix::API::CRUDE/;

# these do not exist in Zabbix but we make them up for consistency's sake
use constant {
    MAP_ELEMENT_TYPE_HOST => 0,
    MAP_ELEMENT_TYPE_MAP => 1,
    MAP_ELEMENT_TYPE_TRIGGER => 2,
    MAP_ELEMENT_TYPE_HOSTGROUP => 3,
    MAP_ELEMENT_TYPE_IMAGE => 4
};

our @EXPORT_OK = qw/
MAP_ELEMENT_TYPE_HOST
MAP_ELEMENT_TYPE_MAP
MAP_ELEMENT_TYPE_TRIGGER
MAP_ELEMENT_TYPE_HOSTGROUP
MAP_ELEMENT_TYPE_IMAGE/;

our %EXPORT_TAGS = (
    map_element_types => [
        qw/MAP_ELEMENT_TYPE_HOST
        MAP_ELEMENT_TYPE_MAP
        MAP_ELEMENT_TYPE_TRIGGER
        MAP_ELEMENT_TYPE_HOSTGROUP
        MAP_ELEMENT_TYPE_IMAGE/
    ],
);

sub id {

    ## mutator for id

    my ($self, $value) = @_;

    if (defined $value) {

        $self->data->{sysmapid} = $value;
        return $self->data->{sysmapid};

    } else {

        return $self->data->{sysmapid};

    }

}

sub prefix {

    my (undef, $suffix) = @_;

    if ($suffix) {

        if ($suffix =~ m/id(s?)/) {

            return 'sysmap'.$suffix;

        }

        return 'map'.$suffix;

    } else {

        return 'map';

    }

}

sub extension {

    return ( output => 'extend',
             select_selements => 'extend' );

}

sub collides {

    my $self = shift;

    return @{$self->{root}->query(method => $self->prefix('.get'),
                                  params => { filter => { name => $self->data->{name} }})};

}

sub hosts {

    ## mutator for map elements that are hosts

    my ($self, $value) = @_;

    if (defined $value) {

        my @new_selements;

        foreach my $selement (@{$self->data->{selements}}) {

            ## keep selements that are not hosts

            push @new_selements, ($selement)
                unless (exists $_->{host}
                        or $selement->{elementtype} == MAP_ELEMENT_TYPE_HOST);

        }

        ## now add the new selements passed as an arrayref

        push @new_selements, @{$value};

        ## finally clobber the existing selements

        $self->data->{selements} = \@new_selements;

    } else {

        return [ grep { exists $_->{host} or $_->{elementtype} == MAP_ELEMENT_TYPE_HOST } @{$self->data->{selements}} ];

    }

}

sub push {

    # override CRUDE's push()

    my $self = shift;

    foreach my $item (@{$self->data->{selements}}) {

        if (exists $item->{host}) {

            if (eval { $item->{host}->isa('Zabbix::API::Host') }) {

                $item->{host}->push;

                $item->{elementtype} = MAP_ELEMENT_TYPE_HOST;
                $item->{elementid} = $item->{host}->id;

                # defaults -- no idea what good values for iconid_* would be
                $item->{iconid_on} //= 0;
                $item->{iconid_disabled} //= 0;
                $item->{iconid_maintenance} //= 0;
                $item->{iconid_off} //= 100100000000036;
                $item->{iconid_unknown} //= 0;

                # use the hostname as a default label
                $item->{label} //= $item->{host}->data->{host};

                delete $item->{host};

            } else {

                croak 'Type mismatch: host attribute should be an instance of Zabbix::API::Host';

            }

        }

    }

    if ($self->collides) {

        $self->delete;
        delete $self->data->{sysmapid};

    }

    return $self->SUPER::push;

}

1;
__END__
=pod

=head1 NAME

Zabbix::API::Map -- Zabbix map objects

=head1 SYNOPSIS

  use Zabbix::API::Map;

  # TODO write the rest

=head1 DESCRIPTION

Handles CRUD for Zabbix map objects.

This is a subclass of C<Zabbix::API::CRUDE>.

=head1 METHODS

=over 4

=item hosts([HOSTS])

Specific mutator for the C<selements> array.  Setting the selements through this
actually only has an effect on host type elements (that is, both elements that
have the correct C<elementtype> and elements that have a C<host> element).  All
other types are ignored.

=item push()

This method handles extraneous C<< host => Zabbix::API::Host >> attributes in
the selements array, transforming them into C<elementid> and C<elementtype>
attributes (and setting the C<label> attribute to the hostname if it isn't set
already), and pushing the hosts to the server if they don't exist already.

Overriden from C<Zabbix::API::CRUDE>.

B<** WARNING **> Due to the way maps API calls are implemented in Zabbix,
updating a map will delete it and create it anew.  The C<sysmapid> B<will>
change if you push an existing map.

=back

=head1 EXPORTS

The various integers representing map element types are implemented as constants:

  MAP_ELEMENT_TYPE_HOST
  MAP_ELEMENT_TYPE_MAP
  MAP_ELEMENT_TYPE_TRIGGER
  MAP_ELEMENT_TYPE_HOSTGROUP
  MAP_ELEMENT_TYPE_IMAGE

Nothing is exported by default; you can use the tag C<:map_element_types> (or
import by name).

=head1 SEE ALSO

L<Zabbix::API::CRUDE>.

=head1 AUTHOR

Fabrice Gabolde <fabrice.gabolde@uperto.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 SFR

This library is free software; you can redistribute it and/or modify it under
the terms of the GPLv3.

=cut
