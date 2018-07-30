package Transport::AU::PTV::Stops;
$Transport::AU::PTV::Stops::VERSION = '0.01';
use strict;
use warnings;
use 5.010;

use parent qw(Transport::AU::PTV::Collection);
use parent qw(Transport::AU::PTV::NoError);

use Transport::AU::PTV::Error;
use Transport::AU::PTV::Stop;


sub new {
    my ($class, $api, $args_r) = @_;
    my %stops;

    $stops{api} = $api;
    my $api_response = $api->request("/v3/stops/route/$args_r->{route_id}/route_type/$args_r->{route_type}");
    return $api_response if $api_response->error;

    foreach (@{$api_response->content->{stops}}) {
        push @{$stops{collection}}, Transport::AU::PTV::Stop->new($api, { route_id => $args_r->{route_id}, stop => $_ });
    }

    return bless \%stops, $class;
}




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Transport::AU::PTV::Stops

=head1 VERSION

version 0.01

=head1 NAME

Transport::AU::PTV::Stop - a stop on the Victorian Public Transport Network

=head1 SYNOPSIS 

    # Retrieve from a route
    $stops = Transport::AU::PTV->new({ ... })->routes->find(name => 'Upfield)->stops;

=head1 Description

L<Transport::AU::PTV::Stops> is a collection of L<Transport::AU::PTV::Stop> objects. It inherits all of the methods present in its parent L<Transport::AU::PTV::Collecton> class.

=head1 Methods

=head2 new

    my $stops = Transport::AU::PTV::Stops( Transport::AU::PTV::APIRequest->new({ ... }), { route_id => 15, route_type => 0 });

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
