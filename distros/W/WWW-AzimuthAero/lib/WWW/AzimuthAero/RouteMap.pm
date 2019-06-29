package WWW::AzimuthAero::RouteMap;
$WWW::AzimuthAero::RouteMap::VERSION = '0.31';

# ABSTRACT: Route map representation


use utf8;   # important cause of L<WWW::AzimuthAero::RouteMap/neighbor_airports>
use Carp;
use List::Util qw/uniq first/;
use WWW::AzimuthAero::Utils qw(:all);
use Graph;
use Data::Dumper;


sub new {
    my ( $self, $rm_raw ) = @_;

    confess "Wrong raw route map structure, not a hash"
      unless ( ref($rm_raw) eq 'HASH' );

    bless { raw => $rm_raw }, $self;
}


sub raw {
    return shift->{raw};
}


sub all_cities {
    my ($self) = @_;
    my @res;

    for my $v ( values %{ $self->raw } ) {
        push @res, { NAME => $v->{NAME}, IATA => $v->{IATA} };
    }

    return sort { lc( $a->{NAME} ) cmp lc( $b->{NAME} ) } @res;
}


sub get {
    my ( $self, $what, $by, $val ) = @_;
    my $city = first { $_->{$by} eq $val } $self->all_cities;
    return $city->{$what};
}

sub get_iata_by_azo {
    my ( $self, $azo_code ) = @_;
    return $self->raw->{$azo_code}{IATA};
}


sub route_map_iata {
    my ( $self, @cities ) = @_;
    my $res = {};
    while ( my ( $azo_code, $data ) = each( %{ $self->raw } ) ) {
        $res->{ $self->get_iata_by_azo($azo_code) } = [
            sort  { lc($a) cmp lc($b) }
              map { $self->get_iata_by_azo($_) }
              keys %{ $self->raw->{$azo_code}{ROUTES} }
        ];
    }

    if (@cities) {
        use experimental 'smartmatch';
        while ( my ( $k, $v ) = each(%$res) ) {
            delete $res->{$k} unless ( $k ~~ @cities );
            @$v = grep { $_ ~~ @cities } @$v;
        }
    }

    return $res;
}


sub neighbor_airports {
    return {
        'Ростов-на-Дону'  => [qw/Краснодар/],    # KRR
        'Москва'          => [qw/Калуга/],       # KLG
        'Санкт-Петербург' => [qw/Псков/]         # PKV
    };
}


sub get_neighbor_airports_iata {
    my ( $self, $city_iata ) = @_;

    my $city = first { $_->{IATA} eq $city_iata } $self->all_cities;
    return
      map { $self->get( 'IATA', 'NAME', $_ ) }
      @{ $self->neighbor_airports->{ $city->{NAME} } };

}


sub transfer_routes {
    my ( $self, %params ) = @_;

    my $raw = $self->route_map_iata();

    # warn "IATA map : ".Dumper $raw;

    my $g = Graph::Undirected->new;

    while ( my ( $from, $destinations ) = each(%$raw) ) {
        for my $to (@$destinations) {
            $g->add_edge( $from, $to );    # add_weighted_edge if price
        }
    }

    # print $g; # OK

    # внутри могут быть уже маршруты с пересадками, внимательнее!
    return $self->_all_paths_btw_vertexes_w_l2(
        graph => $g,
        v1    => $params{from},
        v2    => $params{to}
    );

}

sub _all_paths_btw_vertexes_w_l2 {
    my ( $sef, %params ) = @_;

    my $g = $params{graph};
    my @res;

    #my ( $v1, $v2, $max_path_length ) = @_;
    for my $neighbour_of_v1 ( $g->neighbours( $params{v1} ) ) {
        next if $params{v2} eq $neighbour_of_v1;    # direct route
        for
          my $neighbour_of_neighbour_of_v1 ( $g->neighbours($neighbour_of_v1) )
        {
            next
              if $params{v1} eq
              $neighbour_of_neighbour_of_v1;        # ignore backlink to start
            push @res, [ $params{v1}, $neighbour_of_v1, $params{v2} ]
              if $params{v2} eq $neighbour_of_neighbour_of_v1;
        }
    }

    return [ uniq @res ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::AzimuthAero::RouteMap - Route map representation

=head1 VERSION

version 0.31

=head1 SYNOPSIS

    my $rm = WWW::AzimuthAero::RouteMap->new($route_map_raw_hash);
    $rm->route_map_iata()

=head1 DESCRIPTION

    https://azimuth.aero/ru/about/flight-map

=head1 METHODS

=head2 new

    my $rm = WWW::AzimuthAero::RouteMap->new($route_map_raw_hash);

=head2 new

    Return hash with original route map parsed from site

=head2 all_cities

Return sorted list of city names in route map

    print $rm->all_cities()    
    print join(',' map { "\'". $_ ."\'" } $rm->all_cities() ); # for json array

=head2 get

Universal accessor function for route map, wrapper under L<WWW::AzimuthAero::RouteMap/all_cities>

    $rm->get( $which_property, $by_what_property, $what_property_val )

Examples:

    $rm->get('IATA', 'NAME', 'Ростов-на-Дону')
    $rm->get('IATA', 'AZO', 'РОВ')

=head2 route_map_iata

Return hash with IATA route map

    perl -Ilib -MWWW::AzimuthAero -MData::Dumper -e 'my $x = WWW::AzimuthAero->new->route_map->route_map_iata; warn Dumper $x;'

Amount of cities

    my $x = WWW::AzimuthAero->new->route_map->route_map_iata; print scalar values %$x;

Amount of all routes

    perl -Ilib -MWWW::AzimuthAero -e 'my $x = WWW::AzimuthAero->new->route_map->route_map_iata; my $i = 0; $i+= scalar @$_ for values %$x; print $i;'

Params:

    cities 

    perl -Ilib -MWWW::AzimuthAero -MData::Dumper -e 'my $x = WWW::AzimuthAero->new->route_map->route_map_iata('ROV', 'LED', 'KRR'); warn Dumper $x;'

=head2 neighbor_airports

Return hash of airports that are no more than 4 hours by train from each other 

For now it's manually hardcoded

    {
        'Ростов-на-Дону'    => [qw/Краснодар/],
        'Москва'            => [qw/Калуга/],  
        'Санкт-Петербург'   => [qw/Псков/]
    };

Cities are set by name, not IATA code, for convenience

When you set new city please check it's availability at L<WWW::AzimuthAero::RouteMap/all_cities>

TO-DO: check correctness with Yandex Maps API and RZD API

=head2 get_neighbor_airports_iata

Return list of IATA codes of neighbor airports based on L<WWW::AzimuthAero::RouteMap/neighbor_airports>

    $rm->get_neighbor_airports_iata('LED') # ( 'PKV' )

=head2 transfer_routes

Convert route map to L<Graph> object and return ARRAYref of routes with one transfer maximum

    perl -Ilib -MData::Dumper -MWWW::AzimuthAero -e 'my $x = WWW::AzimuthAero->new->route_map->transfer_routes; warn Dumper $x;'

Params:

    # graph processing options :
    # $params{max_edges} - 2 by default, hardcoded for now
    # $params{check_neighbors}

    # source and destination cities :
    # $params{from} +
    # $params{to} +

    # schedule processing :
    # $params{min}
    # $params{max}
    # $params{max_delay_days}

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
