package Zabbix2::API::Screen;

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Moo;
extends qw/Exporter Zabbix2::API::CRUDE/;

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

my %classes_to_constants = ('Graph' => SCREEN_RESOURCE_GRAPH,
                            'Item' => SCREEN_RESOURCE_SIMPLE_GRAPH,
                            'Map' => SCREEN_RESOURCE_MAP,
                            'Screen' => SCREEN_RESOURCE_SCREEN,
                            'HostGroup' => SCREEN_RESOURCE_HOSTGROUP_TRIGGERS,
                            'Host' => SCREEN_RESOURCE_HOST_TRIGGERS);

my %constants_to_classes = reverse %classes_to_constants;

sub _readonly_properties {
    return {
        screenid => 1,
    };
}

before 'update' => sub {
    # the documentation makes no mention of templateid, but it does
    # exist for screens.  you can set it at creation time but then you
    # can never update it
    my ($self) = @_;
    delete $self->data->{templateid};
};

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

sub _prefix {
    my (undef, $suffix) = @_;
    if ($suffix) {
        return 'screen'.$suffix;
    } else {
        return 'screen';
    }
}

sub _extension {
    return (output => 'extend',
            selectScreenItems => 'extend');
}

sub _screenitem_to_object {
    my ($self, $resource) = @_;
    if (my $class = $constants_to_classes{$resource->{resourcetype}}) {
        # only macros need an instance to call _prefix() so this should
        # be safe
        $class =~ s/^(?:Zabbix2::API::)?/Zabbix2::API::/;
        return $self->root->fetch_single($class, params => { $class->_prefix('ids') => [ $resource->{resourceid} ]});
    } else {
        # can't map this!
        return $resource;
    }    
}

sub _object_to_screenitem {
    my ($self, $object, %options) = @_;
    my $resourcetype = $classes_to_constants{$object->short_class};
    if (defined $resourcetype) {
        return {
            resourcetype => $resourcetype,
            resourceid => $object->id,
            %options,
        };
    } else {
        # not mapped.  assume it's not an object at all, merge with
        # the options, hope for the best
        return { %{$object}, %options };
    }
}

sub items {
    my $self = shift;
    return [ map { $self->_screenitem_to_object($_) } @{$self->data->{screenitems}} ];
}

sub get_item_at {
    my ($self, %options) = @_;
    return map { $self->_screenitem_to_object($_) }
           grep { $_->{x} == $options{x} and $_->{y} == $options{y} }
           @{$self->data->{screenitems}};
}

sub set_item_at {
    my ($self, $object, %options) = @_;
    # change hsize and vsize accordingly
    # find if an existing screenitem needs to be replaced
    my $candidate = grep { $_->{x} == $options{x} and $_->{y} == $options{y} }
                    @{$self->data->{screenitems}};
    if ($candidate) {
        %{$candidate} = %{$self->_object_to_screenitem($object, %options)};
    } else {
        push @{$self->data->{screenitems}}, $self->_object_to_screenitem($object, %options);
    }
    $self->data->{hsize} = max($self->data->{hsize} // 0, $options{x} + 1);
    $self->data->{vsize} = max($self->data->{vsize} // 0, $options{y} + 1);
    return $self;
}

1;
__END__
=pod

=head1 NAME

Zabbix2::API::Screen -- Zabbix screen objects

=head1 SYNOPSIS

  use Zabbix2::API::Screen;
  # initialize a screen object...
  my $screen = Zabbix2::API::Screen->new(root => $zabber,
                                         data => { name => 'This screen brought to you by Zabbix2::API' });
  
  # fetch a graph...
  my $graph = $zabber->fetch_single('Graph', params => { search => { name => 'CPU load' },
                                                         filter => { host => 'Zabbix Server' } });
  
  # put the graph in the screen...
  $screen->set_item_at($graph, 'x' => 0, 'y' => 0);
  
  # create the screen on the server
  $screen->create;

=head1 DESCRIPTION

Handles CRUD for Zabbix screen objects.

This is a subclass of C<Zabbix2::API::CRUDE>; see there for inherited
methods.

=head1 METHODS

=head2 get_item_at

  my $thing = $screen->get_item_at(x => $x, y => $y);

Returns the resource at the coordinates provided.  If the resource's
type is one of

=over 4

=item Graph

=item Item

=item Map

=item Screen

=item HostGroup

=item Host

=back

then this will cause the API to fetch the screen item's data and
return it as a L<Zabbix2::API> object (i.e. L<Zabbix2::API::Graph>,
etc.).  Otherwise, a hashref of screen item properties will be
returned; see the L<screen item
documentation|https://www.zabbix.com/documentation/2.2/manual/api/reference/screenitem/object>
for details.

=head2 items

  my $all_the_things = $screen->items;

Like C<get_item_at>, but for all of the screen's items.  This causes
one API method call for each resource that can be mapped.

=head2 set_item_at

  $screen->set_item_at($thing, x => $x, y => $y, %other_opts);
  $screen->update;

Sets the resource to be displayed at the coordinates provided.  The
first argument should be either a hashref of screen item properties
(see the L<screen item
documentation|https://www.zabbix.com/documentation/2.2/manual/api/reference/screenitem/object>)
or an object of a class for which we have a mapping.  The rest of the
arguments should be a hash of screen item properties.  The screen's
horizontal and vertical sizes will be modified to accomodate the new
item's coordinates.

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

These are used to specify the type of resource to use in a screenitem.
They are not exported by default, only on request; or you could import
the C<:resources> tag.

=head1 SEE ALSO

L<Zabbix2::API::CRUDE>.

=head1 AUTHOR

Fabrice Gabolde <fga@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2014 SFR

This library is free software; you can redistribute it and/or modify it under
the terms of the GPLv3.

=cut
