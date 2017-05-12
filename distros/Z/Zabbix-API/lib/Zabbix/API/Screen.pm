package Zabbix::API::Screen;

use strict;
use warnings;
use 5.010;
use Carp;

use parent qw/Exporter Zabbix::API::CRUDE/;

use List::Util qw/max/;

# extracted from frontends/php/include/defines.inc.php
use constant {
    SCREEN_RESOURCE_GRAPH => 0,
    SCREEN_RESOURCE_SIMPLE_GRAPH => 1,
    SCREEN_RESOURCE_MAP => 2,
    SCREEN_RESOURCE_PLAIN_TEXT => 3,
    SCREEN_RESOURCE_HOSTS_INFO => 4,
    SCREEN_RESOURCE_TRIGGERS_INFO => 5,
    SCREEN_RESOURCE_SERVER_INFO => 6,
    SCREEN_RESOURCE_CLOCK => 7,
    SCREEN_RESOURCE_SCREEN => 8,
    SCREEN_RESOURCE_TRIGGERS_OVERVIEW => 9,
    SCREEN_RESOURCE_DATA_OVERVIEW => 10,
    SCREEN_RESOURCE_URL => 11,
    SCREEN_RESOURCE_ACTIONS => 12,
    SCREEN_RESOURCE_EVENTS => 13,
    SCREEN_RESOURCE_HOSTGROUP_TRIGGERS => 14,
    SCREEN_RESOURCE_SYSTEM_STATUS => 15,
    SCREEN_RESOURCE_HOST_TRIGGERS => 16,
};

our @EXPORT_OK = qw/SCREEN_RESOURCE_GRAPH SCREEN_RESOURCE_SIMPLE_GRAPH SCREEN_RESOURCE_MAP SCREEN_RESOURCE_PLAIN_TEXT SCREEN_RESOURCE_HOSTS_INFO SCREEN_RESOURCE_TRIGGERS_INFO SCREEN_RESOURCE_SERVER_INFO SCREEN_RESOURCE_CLOCK SCREEN_RESOURCE_SCREEN SCREEN_RESOURCE_TRIGGERS_OVERVIEW SCREEN_RESOURCE_DATA_OVERVIEW SCREEN_RESOURCE_URL SCREEN_RESOURCE_ACTIONS SCREEN_RESOURCE_EVENTS SCREEN_RESOURCE_HOSTGROUP_TRIGGERS SCREEN_RESOURCE_SYSTEM_STATUS SCREEN_RESOURCE_HOST_TRIGGERS/;

our %EXPORT_TAGS = (
    resources => [ qw/SCREEN_RESOURCE_GRAPH SCREEN_RESOURCE_SIMPLE_GRAPH SCREEN_RESOURCE_MAP SCREEN_RESOURCE_PLAIN_TEXT SCREEN_RESOURCE_HOSTS_INFO SCREEN_RESOURCE_TRIGGERS_INFO SCREEN_RESOURCE_SERVER_INFO SCREEN_RESOURCE_CLOCK SCREEN_RESOURCE_SCREEN SCREEN_RESOURCE_TRIGGERS_OVERVIEW SCREEN_RESOURCE_DATA_OVERVIEW SCREEN_RESOURCE_URL SCREEN_RESOURCE_ACTIONS SCREEN_RESOURCE_EVENTS SCREEN_RESOURCE_HOSTGROUP_TRIGGERS SCREEN_RESOURCE_SYSTEM_STATUS SCREEN_RESOURCE_HOST_TRIGGERS/ ]
    );

sub new {

    my ($class, %args) = @_;

    my $self = $class->SUPER::new(%args);

    $self->data->{screenitems} = [] unless defined $self->data->{screenitems};

    return $self;

}

sub id {

    ## mutator for id

    my ($self, $value) = @_;

    if (defined $value) {

        $self->data->{screenid} = $value;
        return $self->data->{screenid};

    } else {

        return $self->data->{screenid};

    }

}

sub prefix {

    my (undef, $suffix) = @_;

    if ($suffix) {

        return 'screen'.$suffix;

    } else {

        return 'screen';

    }

}

sub extension {

    return ( output => 'extend',
             select_screenitems => 'extend' );

}

sub collides {

    my $self = shift;

    return @{$self->{root}->query(method => $self->prefix('.get'),
                                  params => { filter => { name => $self->data->{name} } })};

}

sub items {

    ## mutator for items

    my ($self, $value) = @_;

    if (defined $value) {

        if (@{$value}) {

            # *some* validation, at least
            croak 'Some screen items did not specify all their coordinates'
                if grep { not exists $_->{'x'}
                          or not exists $_->{'y'} } @{$value};

            # compute screen hsize and vsize from the screenitems max coordinates
            my $hsize = max(map { $_->{'x'} } @{$value})+1;
            my $vsize = max(map { $_->{'y'} } @{$value})+1;

            $self->data->{hsize} = $hsize;
            $self->data->{vsize} = $vsize;

        } else {

            # $value is an empty arrayref
            $self->data->{hsize} = 0;
            $self->data->{vsize} = 0;

        }

        $self->data->{screenitems} = $value;
        return $self->data->{screenitems};

    } else {

        return $self->data->{screenitems};

    }

}

sub push {

    # override CRUDE's push()

    my $self = shift;

    foreach my $item (@{$self->data->{screenitems}}) {

        if (exists $item->{graph}) {

            if (eval { $item->{graph}->isa('Zabbix::API::Graph') }) {

                $item->{graph}->push;

                $item->{resourcetype} = SCREEN_RESOURCE_GRAPH;
                $item->{resourceid} = $item->{graph}->id;
                delete $item->{graph};

            } else {

                croak 'Type mismatch: graph attribute should be an instance of Zabbix::API::Graph';

            }
        } elsif (exists $item->{simplegraph}) {

            if (eval { $item->{simplegraph}->isa('Zabbix::API::Item') }) {

                $item->{simplegraph}->push;

                $item->{resourcetype} = SCREEN_RESOURCE_SIMPLE_GRAPH;
                $item->{resourceid} = $item->{simplegraph}->id;
                delete $item->{simplegraph};

            } else {
                    croak 'Type mismatch: graph attribute should be an instance of Zabbix::API::Item';
            }

        }

    }

    return $self->SUPER::push;

}

1;
__END__
=pod

=head1 NAME

Zabbix::API::Screen -- Zabbix screen objects

=head1 SYNOPSIS

  use Zabbix::API::Screen;

  # TODO write the rest

=head1 DESCRIPTION

Handles CRUD for Zabbix screen objects.

This is a subclass of C<Zabbix::API::CRUDE>.

=head1 METHODS

=over 4

=item items([ITEMS])

Mutator for the screenitems array.  Setting the screenitems through this means
you won't have to set the C<hsize> and C<vsize> data attributes accordingly, as
that will be done for you.  It also checks that the C<x> and C<y> attributes
have been specified for all the screenitems and throws an exception otherwise.

=item push()

This method handles extraneous C<< graph => Zabbix::API::Graph >> attributes in
the screenitems array, transforming them into C<resourceid> and C<resourcetype>
attributes, and pushing the graphs to the server if they don't exist already.

This means you can put C<Zabbix::API::Graph> objects in your data and the module
will Do The Right Thing (assuming you agree with my definition of the Right
Thing).  Graphs that have been created this way will not be removed from the
server if they are removed from the screen, however.

Since graphs do the same thing with their C<Item> graphitems, you can create a
bunch of items, put them in a bunch of graphs, put those in a screen, push the
screen, sit back and enjoy the fireworks.

Overriden from C<Zabbix::API::CRUDE>.

=back

=head1 EXPORTS

A bunch of constants:

  SCREEN_RESOURCE_GRAPH
  SCREEN_RESOURCE_SIMPLE_GRAPH
  SCREEN_RESOURCE_MAP
  SCREEN_RESOURCE_PLAIN_TEXT
  SCREEN_RESOURCE_HOSTS_INFO
  SCREEN_RESOURCE_TRIGGERS_INFO
  SCREEN_RESOURCE_SERVER_INFO
  SCREEN_RESOURCE_CLOCK
  SCREEN_RESOURCE_SCREEN
  SCREEN_RESOURCE_TRIGGERS_OVERVIEW
  SCREEN_RESOURCE_DATA_OVERVIEW
  SCREEN_RESOURCE_URL
  SCREEN_RESOURCE_ACTIONS
  SCREEN_RESOURCE_EVENTS
  SCREEN_RESOURCE_HOSTGROUP_TRIGGERS
  SCREEN_RESOURCE_SYSTEM_STATUS
  SCREEN_RESOURCE_HOST_TRIGGERS

These are used to specify the type of resource to use in a screenitem.  They are
not exported by default, only on request; or you could import the C<:resources>
tag.

=head1 SEE ALSO

L<Zabbix::API::CRUDE>.

=head1 AUTHOR

Fabrice Gabolde <fabrice.gabolde@uperto.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 SFR

This library is free software; you can redistribute it and/or modify it under
the terms of the GPLv3.

=cut
