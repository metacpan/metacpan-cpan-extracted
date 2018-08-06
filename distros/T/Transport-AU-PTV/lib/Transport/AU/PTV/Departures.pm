package Transport::AU::PTV::Departures;
$Transport::AU::PTV::Departures::VERSION = '0.03';
# VERSION
# PODNAME
# ABSTRACT: a collection of departures on the Victorian Public Transport Network.

use strict;
use warnings;
use 5.010;

use parent qw(Transport::AU::PTV::Collection);
use parent qw(Transport::AU::PTV::NoError);

use Transport::AU::PTV::Error;
use Transport::AU::PTV::Departure;


sub new {
    my ($class, $api, $args_r) = @_;
    my %departures;
    my ($stop_id, $route_id, $route_type) = delete @{$args_r}{qw(stop_id route_id route_type)};

    $departures{api} = $api;
    my $request_uri = "/v3/departures/route_type/$route_type/stop/$stop_id" . ($route_id ? "/route/$route_id" : "");
    my $api_response = $api->request($request_uri, $args_r);

    return $api_response if $api_response->error;


    foreach (@{$api_response->content->{departures}}) {
        push @{$departures{collection}}, Transport::AU::PTV::Departure->new($api, $_);
    }

    return bless \%departures, $class;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Transport::AU::PTV::Departures - a collection of departures on the Victorian Public Transport Network.

=head1 VERSION

version 0.03

=head1 SYNOPSIS

   # Get the departures for a stop
    my $departures = Transport::AU::PTV->new
    ->routes->find({ name => 'Upfield' })
    ->stops->find({ name => "Coburg Station" })
    ->departures({ max_results => 1 });

=head1 NAME

Transport::AU::PTV::Departures - a collection of departures for a particular stop on the Victorian Public Transport network.

=head1 METHODS

=head2 new

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
