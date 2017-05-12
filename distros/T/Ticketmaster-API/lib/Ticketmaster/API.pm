package Ticketmaster::API;

use 5.006;
use strict;
use warnings;

use Carp;
use JSON::XS;
use LWP::UserAgent;

=head1 NAME

Ticketmaster::API - start interacting with Ticketmaster's APIs

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

Core module to facilitate interacting with Ticketmaster's APIs.

Unless you are creating unique way to connect to Ticketmaster's API you probably
don't want this module.  Please see one of the following:

    Ticketmaster::API::Discover

To be able to interact with Ticketmaster's APIs you'll need to get an API key.

General documentation can be found here: http://ticketmaster-api.github.io


=head1 NOTES

=over 2

=item Mozilla::CA

Since connections are made via https Mozilla::CA will most likely need to be installed.

=back


=head1 SUBROUTINES/METHODS

=head2 new

Create a new instance of Ticketmaster::API.

  # use the default base_uri and version infromation
  my $tm_api = Ticketmaster::API->new(api_key => $api_key);

  my $tm_api = Ticketmaster::API->new(
    api_key  => $api_key,
    base_uri => 'https://new_api_endpoint.ticketmaster.com',
    version  => 'v2'
  );

=cut

sub new {
    my $self;
    my $package = shift;
    my $class = ref($package) || $package;

    $self = {@_};
    bless($self, $class);

    $self->base_uri('https://app.ticketmaster.com') unless $self->base_uri;
    $self->version('v1') unless $self->version;
    
    Carp::croak("No api_key provided") unless $self->api_key();

    return $self;
}

=head2 base_uri

Set/Get the base endpoint for the Ticketmaster API.

Default: https://app.ticketmaster.com

=cut
sub base_uri {
    my $self = shift;

    $self->{base_uri} = shift if @_;

    return $self->{base_uri};
}

=head2 base_uri

Set/Get the version of the Ticketmaster API that is currently being hit.

Default: v1

=cut
sub version {
    my $self = shift;

    $self->{version} = shift if @_;

    return $self->{version};
}

=head2 api_key

Set/Get the user's API key to the Ticketmaster API.

=cut
sub api_key {
    my $self = shift;

    $self->{api_key} = shift if @_;

    return $self->{api_key};
}

=head2 get_data

Connect to the TM API to receive the information being requested.

  my $res = $tm_api->get_data(method => 'GET', path_template => '/discovery/%s/events');

=over 2

=item method

The REST method to execute on the endpoint.  IE: GET

=item path_template

A sprintf template that will be combined with the base_uri value to generate the final endpoint.

Example: /discovery/%s/events

The '%s' is the location of the version number of the API being hit.

=item parameters

A hash reference of any parameters that are to be added to the endpoint

=back

=cut
# Requires: method, path_template (sprintf string), parameters (hash ref)
sub get_data {
    my $self = shift;
    my %args = @_;

    my $method = $args{method} || Carp::croak("No method provided (GET)");
    my $path_template = $args{path_template} || Carp::croak("No URI template provided");
    my %parameters = exists $args{parameters} ? %{$args{parameters}} : ();

    my $uri = $self->base_uri;
    $uri .= '/' unless $uri =~ /\/$/;
    $uri .= sprintf($path_template, $self->version());

    $uri .= '?apikey=' . $self->api_key();

    foreach my $key (keys %parameters) {
        $uri .= '&' . $key . '=' . $parameters{$key};
    }

    my $ua = LWP::UserAgent->new;

    my $req = HTTP::Request->new($method => $uri);

    my $res = $ua->request($req);

    if ($res->is_success) {
        return decode_json($res->content);
    }
    else {
        Carp::croak("Error: " . $res->status_line);
    }
}

=head1 AUTHOR

Erik Tank, C<< <tank at jundy.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ticketmaster-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ticketmaster-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ticketmaster::API


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Ticketmaster-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ticketmaster-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Ticketmaster-API>

=item * Search CPAN

L<http://search.cpan.org/dist/Ticketmaster-API/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Erik Tank.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Ticketmaster::API
