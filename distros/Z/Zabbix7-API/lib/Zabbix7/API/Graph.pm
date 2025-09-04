package Zabbix7::API::Graph;

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use URI;
use Params::Validate qw/validate :types/;

use Moo;
extends qw/Exporter Zabbix7::API::CRUDE/;

# extracted from frontends/php/include/defines.inc.php
use constant {
    GRAPH_TYPE_NORMAL => 0,
    GRAPH_TYPE_STACKED => 1,
    GRAPH_TYPE_PIE => 2,
    GRAPH_TYPE_EXPLODED => 3,
};

our @EXPORT_OK = qw/GRAPH_TYPE_NORMAL GRAPH_TYPE_STACKED GRAPH_TYPE_PIE GRAPH_TYPE_EXPLODED/;

our %EXPORT_TAGS = (
    graphtypes => [ qw/GRAPH_TYPE_NORMAL GRAPH_TYPE_STACKED GRAPH_TYPE_PIE GRAPH_TYPE_EXPLODED/ ]
);

use Zabbix7::API::GraphItem;

has 'graphitems' => (is => 'rw');
has 'color_wheel' => (is => 'ro', clearer => 1, lazy => 1, builder => '_build_color_wheel');

sub make_color_wheel {
    my ($class, $colors) = @_;
    return sub {
        state $iterator = 0;
        my $color = $colors->[$iterator];
        $iterator++;
        $iterator = $iterator % scalar(@{$colors});
        return $color;
    };
}

sub _build_color_wheel {
    my $self = shift;
    return $self->make_color_wheel([qw/1C1CCC 1CCC1C CC1C1C FDFD49 9A1C9A 1CCCCC FD8C1C/]);
}

sub add_items {
    my ($self, @items) = @_;
    my @graphitems = map {
        Zabbix7::API::GraphItem->new(
            root => $self->root,
            data => {
                itemid => $_->id,
                color => $self->color_wheel->(),
            }
        )
    } @items;
    if ($self->id) {
        push @{$self->graphitems}, @graphitems;
    } else {
        $self->graphitems(\@graphitems);
    }
    Log::Any->get_logger->debug("Added " . scalar @graphitems . " graph items to graph ID: " . ($self->id // 'new'));
    return @graphitems;
}

sub id {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->data->{graphid} = $value;
        return $self->data->{graphid};
    }
    return $self->data->{graphid};
}

sub _readonly_properties {
    return {
        graphid => 1,
        flags => 1,
        templateid => 1,
    };
}

sub _prefix {
    my ($class, $suffix) = @_;
    return 'graph' . ($suffix // '');
}

sub _extension {
    return (
        output => 'extend',
        selectHosts => ['hostid', 'host'], # Updated for Zabbix 7.0
        selectGraphItems => 'extend',
    );
}

sub name {
    my $self = shift;
    return $self->data->{name} || '???';
}

sub url {
    my $self = shift;
    my %args = validate(@_, {
        width => { type => SCALAR, optional => 1, regex => qr/^\d+$/ },
        height => { type => SCALAR, optional => 1, regex => qr/^\d+$/ },
        period => { type => SCALAR, optional => 1, regex => qr/^\d+$/ },
        stime => { type => SCALAR, optional => 1, regex => qr/^\d{14}$/ }, # Changed from start_time
    });

    my $base_url = $self->{root}->{server};
    my $url = URI->new($base_url);
    my @path_segments = $url->path_segments;

    # Zabbix 7.0 uses zabbix.php with action parameter
    $path_segments[-1] = 'zabbix.php';
    $url->path_segments(@path_segments);

    my %query_params = (
        action => 'charts.view',
        view_as => ($self->data->{type} == GRAPH_TYPE_NORMAL || $self->data->{type} == GRAPH_TYPE_STACKED)
            ? 'showgraph' : 'showvalues',
        filter_graphid => $self->id,
        %args,
    );
    $url->query_form(%query_params);

    Log::Any->get_logger->debug("Generated URL for graph ID: " . $self->id . ": $url");
    return $url;
}

sub _map_graphitems_to_property {
    my ($self) = @_;
    $self->data->{gitems} = [ map { $_->data } @{$self->graphitems // []} ];
    Log::Any->get_logger->debug("Mapped " . scalar(@{$self->data->{gitems}}) . " graph items to property for graph ID: " . ($self->id // 'new'));
    return;
}

sub _map_property_to_graphitems {
    my ($self) = @_;
    my @graphitems = map {
        Zabbix7::API::GraphItem->new(root => $self->root, data => $_)
    } @{$self->data->{gitems} // []};
    $self->graphitems(\@graphitems);
    Log::Any->get_logger->debug("Mapped " . scalar(@graphitems) . " graph items from property for graph ID: " . ($self->id // 'new'));
    return;
}

before 'create' => \&_map_graphitems_to_property;
before 'update' => \&_map_graphitems_to_property;
after 'pull' => \&_map_property_to_graphitems;
around 'new' => sub {
    my ($orig, @rest) = @_;
    my $graph = $orig->(@rest);
    $graph->_map_property_to_graphitems;
    return $graph;
};

1;
__END__
=pod

=head1 NAME

Zabbix7::API::Graph -- Zabbix graph objects

=head1 SYNOPSIS

  use Zabbix7::API::Graph;
  
  my $graph = $zabbix->fetch_single('Graph', params => { ... });
  
  my $items = $zabbix->fetch('Item', params => { ... });
  $graph->add_items(@{$items});
  $graph->update;
  
  $graph->delete;

=head1 DESCRIPTION

Handles CRUD for Zabbix graph objects.

This is a subclass of C<Zabbix7::API::CRUDE>.

=head1 ATTRIBUTES

=head2 color_wheel

(read-only coderef, with predicate and clearer)

This attribute is used to generate hex triplets representing colors.
See C<make_color_wheel> for a complete usage explanation.

=head2 graphitems

(read-write arrayref of L<Zabbix7::API::GraphItem> instances)

This attribute is populated automatically when the Perl object is
updated from the "gitems" server property (i.e. when the C<pull>
method is called).

Likewise, it is automatically used to populate the "gitems" property
before either C<create> or C<update> are called.

=head1 METHODS

=head2 add_items

  my $items = $zabbix->fetch('Item', ...);
  $graph->add_items(@{$items});

This method is a shortcut to create graphs with the least hassle.  It
pushes new graph items in the graph's C<graphitems> attribute,
providing only the corresponding item ID and a color generated from
the graph's C<color_wheel>.

Returns the L<Zabbix7::API::GraphItem> objects created.

=head2 make_color_wheel

  my $color_wheel = Zabbix7::API::Graph->make_color_wheel([ qw/1C1CCC 1CCC1C CC1C1C/ ... ]);

This class method returns an iterator over its argument.  This makes
it easy to repeatedly generate colors for graph items.  Once the last
element in the color array is reached, the iterator wraps around.

The default color wheel in the C<color_wheel> attribute is

  [qw/1C1CCC 1CCC1C CC1C1C FDFD49 9A1C9A 1CCCCC FD8C1C/]
  # royal blue, green, dark red, yellow, purple, turquoise, orange

which is a decently contrasted set of not-too-flashy colors, and
happens to be the set of colors used in a CPU utilization graph at
work.

=head2 url

  my $url = $graph->url(width => $width,
                        height => $height,
                        period => $period,
                        start_time => $start_time);

This method returns a URL to an image on the Zabbix server.  The image
of width C<width> and height C<height> will represent the current
graph, plotted for data starting at C<start_time> (a UNIX timestamp)
over C<period> seconds.  (Note that the height and width parameters
describe the plotting area; Zabbix will then make the final image
bigger so that the legend and title can fit.)  It uses the current
connection's host name to guess what path to base the URL on.

All parameters are optional.

If the current user agent has cookies enabled, you can even fetch the
image directly, since your API session is completely valid for all
regular requests:

  my $zabbix = Zabbix7::API->new(server => ...,
                                 ua => LWP::UserAgent->new(cookie_jar => { file => 'cookie.jar' }),
                                 ...);
  my $graph = $zabbix->fetch_single('Graph', ...);
  my $response = $zabbix->useragent->get($graph->url);
  open my $image, '>', 'graph.png' or die $!;
  $image->print($response->decoded_content);
  $image->close;

=head1 EXPORTS

Some constants:

  GRAPH_TYPE_NORMAL
  GRAPH_TYPE_STACKED
  GRAPH_TYPE_PIE
  GRAPH_TYPE_EXPLODED

They are not exported by default, only on request; or you could import
the C<:graphtypes> tag.

A bunch of constants (graphitem types, axis stuff, ...) are not
defined.  If you need them, send me a feature request (or better, a
pull request).

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
