package Transport::AU::PTV::Stop;
$Transport::AU::PTV::Stop::VERSION = '0.03';
# VERSION
# PODNAME
# ABSTRACT: a stop on the Victorian Public Transport Network.

use strict;
use warnings;
use 5.010;

use parent qw(Transport::AU::PTV::NoError);

use Transport::AU::PTV::Error;
use Transport::AU::PTV::Departures;


sub new {
    my $class = shift;
    my ($api, $args_r) = @_;

    return bless { api => $api, %{ $args_r } }, $class;
}


sub name { return $_[0]->{stop}{stop_name} };


sub type { return $_[0]->{stop}{route_type} };


sub id { return $_[0]->{stop}{stop_id} };


sub route_id { return $_[0]->{route_id} };


sub departures {
    my $self = shift;
    my ($args_r) = @_;
    $args_r //= {};

    return Transport::AU::PTV::Departures->new( $self->{api}, { %{$args_r}, route_id => $self->route_id, route_type => $self->type, stop_id => $self->id } );

}






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Transport::AU::PTV::Stop - a stop on the Victorian Public Transport Network.

=head1 VERSION

version 0.03

=head1 NAME

Transport::AU::PTV::Stop - a stop on the Victorian Public Transport Network.

=head1 METHODS

=head2 new

    # The 'stop' key in the constructor is the object returned by the API call.
    my $stop = Transport::AU::PTV::Stop->new( Transport::AU::PTV::APIRequest->new({...}), { route_id => 15, stop => { } );

=head2 name

    my $stop_name = $stop->name;

Returns the name of the stop.

=head2 type

    my $stop_type= $stop->type;

Returns the type of stop.

=head2 id

    my $stop_id = $stop->id;

Returns the stop ID.

=head2 route_id

    my $route_id = $stop->route_id;

Returns the route ID for the stop.

=head2 departures

    my $following_departures = $route->departures;
    my $next_departure = $route->departures({ max_results => 1 });

Returns a L<Transport::AU::PTV::Departures> object representing the departures for the stop.

If no arguments are provided, returns all of the departures from the time of the request until the end of the day. B<Note:> the API will not return the estimated departure time unless the C<max_results> argument is provided.

=over 4

=item * 

C<max_results> - Limits the number of results returned. 

=back

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
