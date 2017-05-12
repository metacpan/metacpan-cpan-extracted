package Zabbix::API::Graph;

use strict;
use warnings;
use 5.010;
use Carp;

use Params::Validate qw/validate :types/;
use parent qw/Zabbix::API::CRUDE/;

sub new { 
	my ($class, %args) = @_; 

	my $self = $class->SUPER::new(%args);

	$self->data->{gitems} = [] unless defined $self->data->{gitems}; 

	return $self;
}


sub id {

    ## mutator for id

    my ($self, $value) = @_;

    if (defined $value) {

        $self->data->{graphid} = $value;
        return $self->data->{graphid};

    } else {

        return $self->data->{graphid};

    }

}

sub prefix {

    my (undef, $suffix) = @_;

    if ($suffix) {

        return 'graph'.$suffix;

    } else {

        return 'graph';

    }

}

sub extension {

    return ( output => 'extend',
             select_graph_items => 'extend' );

}

sub collides {

    my $self = shift;

    return @{$self->{root}->query(method => $self->prefix('.get'),
                                  params => { filter => { name => $self->data->{name} },
                                              $self->extension })};

}

sub items {

    ## mutator for graph_items

    my ($self, $value) = @_;

    if (defined $value) {

        $self->data->{gitems} = $value;
        return $self->data->{gitems};

    } else {

        return $self->data->{gitems};

    }

}

sub url {

    ## return url for a graph

    my $self = shift;

    my $base_url = $self->{root}->{server};
    $base_url =~ s{(?:/api_jsonrpc\.php)?$}{};

    my %args = validate(@_, { width => { type => SCALAR, optional => 1, regex => qr/^\d+$/ },
                              period => { type => SCALAR, optional => 1, regex => qr/^\d+$/ },
                              start_time => { type => SCALAR, optional => 1, regex => qr/^\d{14}$/ } });

    my $url = $base_url.'/chart2.php?graphid='.$self->id;
    $url .= '&width='.$args{width} if $args{width};
    $url .= '&period='.$args{period} if $args{period};
    $url .= '&stime='.$args{start_time} if $args{start_time};

    return $url;

}

sub push {

    # override CRUDE's push()

    my ($self, $data) = @_;

    $data //= $self->data;

    foreach my $item (@{$data->{gitems}}) {

        if (exists $item->{item}) {

            if (eval { $item->{item}->isa('Zabbix::API::Item') }) {

                $item->{item}->push;

                $item->{itemid} = $item->{item}->id;

            } else {

                croak 'Type mismatch: item attribute should be an instance of Zabbix::API::Item';

            }

        }

    }

    # copying the anonymous hashes so we can delete stuff without touching the
    # originals
    my $gitems_copy = [ map { { %{$_} } } @{$data->{gitems}} ];

    foreach my $item (@{$gitems_copy}) {

        delete $item->{item};

    }

    # copying the data hashref so we can replace its gitems with the fake
    my $data_copy = { %{$data} };

    # the old switcheroo
    $data_copy->{gitems} = $gitems_copy;

    return $self->SUPER::push($data_copy);

}

sub pull {

    # override CRUDE's pull()

    my ($self, $data) = @_;

    if (defined $data) {

        $self->{data} = $data;

    } else {

        my %stash = map { $_->id => $_ } grep { eval { $_->isa('Zabbix::API::Item') } } @{$self->items};

        $self->SUPER::pull;

        ## no critic (ProhibitCommaSeparatedStatements)
        # restore stashed items that have been removed by pulling
        $self->items(
            [map {
                { %{$_},
                  item =>
                      $stash{$_->{itemid}} // Zabbix::API::Item->new(root => $self->{root},
                                                                     data => { itemid => $_->{itemid} })->pull
                }
             }
             @{$self->items}]
            );
        ## use critic

    }

    return $self;

}

1;
__END__
=pod

=head1 NAME

Zabbix::API::Graph -- Zabbix graph objects

=head1 SYNOPSIS

  use Zabbix::API::Graph;

  # TODO write the rest

=head1 DESCRIPTION

Handles CRUD for Zabbix graph objects.

This is a subclass of C<Zabbix::API::CRUDE>.

=head1 METHODS

=over 4

=item items([ITEMS])

Trivial mutator for the gitems array.

=item push()

This method handles extraneous C<< item => Zabbix::API::Item >> attributes in
the gitems array, transforming them into C<itemid> attributes, and pushing the
items to the server if they don't exist already.  The original item attributes
are kept but hidden from the C<CRUDE> C<push> method, and restored after the
C<pull> method is called.

This means you can put C<Zabbix::API::Item> objects in your data and the module
will Do The Right Thing (assuming you agree with my definition of the Right
Thing).  Items that have been created this way will not be removed from the
server if they are removed from the graph, however.

Overriden from C<Zabbix::API::CRUDE>.

=item url([width => WIDTH], [period => PERIOD], [start_time => START_TIME])

This method returns a URL to an image on the Zabbix server.  The image
of width C<WIDTH> will represent the current graph, plotted for data
starting at C<START_TIME> (a UNIX timestamp) over C<PERIOD> seconds.
It uses the current connection's host name to guess what path to base
the URL on.

All three parameters are optional.

If the current user agent has cookies enabled, you can even fetch the
image directly, since your API session is completely valid for all
regular requests:

  my $zabbix = Zabbix::API->new(server => ...,
                                ua => LWP::UserAgent->new(cookie_jar => { file => 'cookie.jar' }),
                                ...);
  my $graph = $zabbix->fetch_single('Graph', ...);
  my $response = $zabbix->{ua}->get($graph->url);
  open my $image, '>', 'graph.png' or die $!;
  $image->print($response->decoded_content);
  $image->close;

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
