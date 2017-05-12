package Ticketmaster::API::Discovery;

use 5.006;
use strict;
use warnings;

=head1 NAME

Ticketmaster::API::Discovery - search, look up and find event, attractions and venues

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
use parent 'Ticketmaster::API';

my $base_uri = 'discovery/%s';

=head1 SYNOPSIS

    Ticketmaster's Discovery API is used to search, look up and find events, attractions and venues.

    For more information also see: http://ticketmaster-api.github.io/products-and-docs/apis/discovery/

    use Ticketmaster::API::Discovery;

    my $tm_api = Ticketmaster::API::Discovery->new(api_key => 'abc123');
    my $events = $tm_api->search_events();

=head1 SUBROUTINES/METHODS

=head2 search_events

Returns the 20 most recent events for the authenticating user.

Also See: http://ticketmaster-api.github.io/products-and-docs/apis/discovery/#srch-events

    my $ret = $tm_api->search_events();

=cut

sub search_events {
    my $self = shift;
    my $args = {@_};

    return $self->get_data(method => 'GET', path_template => "$base_uri/events.json", parameters => $args);
}

=head2 event_details

Returns the event details by event ID.

Also See: http://ticketmaster-api.github.io/products-and-docs/apis/discovery/#event-details

    my $ret = $tm_api->event_details(id => 1234, ...);

=over 2

=item id

event id

=item ...

other options available in key/value pairs

=back

=cut
sub event_details {
    my $self = shift;
    my $args = {@_};

    my $id = delete $args->{id} || die("No event id provided\n");

    return $self->get_data(method => 'GET', path_template => "$base_uri/events/$id.json", parameters => $args);
}

=head2 event_images

Returns all event images by event ID.

Also See: http://ticketmaster-api.github.io/products-and-docs/apis/discovery/#event-img

  my $ret = $tm_api->event_images(id => 1234, ...);

=over 2

=item id

event id

=item ...

other options available in key/value pairs

=back

=cut
sub event_images {
    my $self = shift;
    my $args = {@_};

    my $id = delete $args->{id} || die("No event id provided\n");

    return $self->get_data(method => 'GET', path_template => "$base_uri/events/$id/images.json", parameters => $args);
}

=head2 search_attractions

Returns available attactions

Also See: http://ticketmaster-api.github.io/products-and-docs/apis/discovery/#search-attractions

  my $ret = $tm_api->search_attractions(...);

=over 2

=item ...

other options available in key/value pairs

=back

=cut
sub search_attractions {
    my $self = shift;
    my $args = {@_};

    return $self->get_data(method => 'GET', path_template => "$base_uri/attractions.json", parameters => $args);
}

=head2 attraction_details

Returns attraction deatils by attraction ID.

Also See: http://ticketmaster-api.github.io/products-and-docs/apis/discovery/#attraction-details

  my $ret = $tm_api->attraction_details(id => 1234, ...);

=over 2

=item id

attraction id

=item ...

other options available in key/value pairs

=back

=cut
sub attraction_details {
    my $self = shift;
    my $args = {@_};

    my $id = delete $args->{id} || die("No attraction id provided\n");

    return $self->get_data(method => 'GET', path_template => "$base_uri/attractions/$id.json", parameters => $args);
}

=head2 search_categories

Returns available categories

Also See: http://ticketmaster-api.github.io/products-and-docs/apis/discovery/#search-categories

  my $ret = $tm_api->search_categories(...);

=over 2

=item ...

other options available in key/value pairs

=back

=cut
sub search_categories {
    my $self = shift;
    my $args = {@_};

    return $self->get_data(method => 'GET', path_template => "$base_uri/categories.json", parameters => $args);
}

=head2 category_details

Returns category deatils by category ID.

Also See: http://ticketmaster-api.github.io/products-and-docs/apis/discovery/#category-details

  my $ret = $tm_api->category_details(id => 1234, ...);

=over 2

=item id

category id

=item ...

other options available in key/value pairs

=back

=cut
sub category_details {
    my $self = shift;
    my $args = {@_};

    my $id = delete $args->{id} || die("No category id provided\n");

    return $self->get_data(method => 'GET', path_template => "$base_uri/categories/$id.json", parameters => $args);
}

=head2 search_venues

Returns available venues

Also See: http://ticketmaster-api.github.io/products-and-docs/apis/discovery/#search-venues

  my $ret = $tm_api->search_venues(...);

=over 2

=item ...

other options available in key/value pairs

=back

=cut
sub search_venues {
    my $self = shift;
    my $args = {@_};

    return $self->get_data(method => 'GET', path_template => "$base_uri/venues.json", parameters => $args);
}

=head2 venue_details

Returns venue deatils by venue ID.

Also See: http://ticketmaster-api.github.io/products-and-docs/apis/discovery/#venue-details

  my $ret = $tm_api->venue_details(id => 1234, ...);

=over 2

=item id

venue id

=item ...

other options available in key/value pairs

=back

=cut
sub venue_details {
    my $self = shift;
    my $args = {@_};

    my $id = delete $args->{id} || die("No venue id provided\n");

    return $self->get_data(method => 'GET', path_template => "$base_uri/venues/$id.json", parameters => $args);
}

=head1 AUTHOR

Erik Tank, C<< <tank at jundy.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ticketmaster-api-discovery at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ticketmaster-API-Discovery>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ticketmaster::API::Discovery


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Ticketmaster-API-Discovery>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ticketmaster-API-Discovery>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Ticketmaster-API-Discovery>

=item * Search CPAN

L<http://search.cpan.org/dist/Ticketmaster-API-Discovery/>

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

1; # End of Ticketmaster::API::Discovery
