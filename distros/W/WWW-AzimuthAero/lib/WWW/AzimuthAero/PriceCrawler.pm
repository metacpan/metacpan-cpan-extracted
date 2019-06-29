package WWW::AzimuthAero::PriceCrawler;
$WWW::AzimuthAero::PriceCrawler::VERSION = '0.31';

# ABSTRACT: Crawler for https://azimuth.aero/

use parent 'WWW::AzimuthAero';
use feature 'say';


sub prepare_requests {
    my ( $self, %params ) = @_;

    my $iata_map = $self->route_map->route_map_iata( $params{cities} );

    my $n = 0;
    if ( $params{verbose} ) {
        say 'Cities total: ' . scalar keys %$iata_map if $params{verbose};
        for my $x ( values %$iata_map ) {
            $n += scalar @$x;
        }
        say
'Amount of WWW::AzimuthAero::get_schedule_dates HTTP requests will be performed: '
          if $params{verbose};
    }

    my @get_requests;
    while ( ( $from, $cities ) = each(%$iata_map) ) {
        for my $to (@$cities) {
            say "$n : get_schedule_dates : $from -> $to" if $params{verbose};
            $n-- if $params{verbose};
            my @dates = $self->get_schedule_dates( from => $from, to => $to );
            for my $date (@dates) {
                push @get_requests, { from => $from, to => $to, date => $date };
            }
        }
    }

    if ( $params{verbose} ) {
        say 'Amount of WWW::AzimuthAero::get HTTP requests will be performed: '
          . scalar @get_requests
          if $params{verbose};
        say 'Total HTTP requests: ' . $n + scalar @get_requests
          if $params{verbose};
    }

    return @get_requests;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::AzimuthAero::PriceCrawler - Crawler for https://azimuth.aero/

=head1 VERSION

version 0.31

=head1 SYNOPSIS

    my $azo_price_crawler = WWW::AzimuthAero::PriceCrawler->new();
    $azo_price_crawler->prepare_requests()

=head1 DESCRIPTION

    Wrappper under L<WWW::AzimuthAero>

=head1 METHODS

=head2 new

See L<WWW::AzimuthAero/new>

=head2 prepare_requests

Return arrray of hashes with params (from, to, date) for WWW::AzimuthAero::get method

    my @l = $azo_price_crawler->prepare_requests( max_date => '18.12.2019', verbose => 1, cities => [ qw/ROV LED/ ] );

In fact, combines L<WWW::AzimuthAero::RouteMap/route_map_iata> and L<WWW::AzimuthAero/get_schedule_dates>

=head3 Params

max_date - '%d.%m.%Y' format, if no specified will looks forward for 2 months, default max_date of L<WWW::AzimuthAero/get_schedule_dates>

verbose - print amount of L<WWW::AzimuthAero/get_schedule_dates> requests and future amount of L<WWW::AzimuthAero/get> requests

cities - filter for L<WWW::AzimuthAero::RouteMap/route_map_iata>

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
