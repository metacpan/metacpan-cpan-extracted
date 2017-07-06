package WWW::Google::APIDiscovery;

$WWW::Google::APIDiscovery::VERSION   = '0.23';
$WWW::Google::APIDiscovery::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

WWW::Google::APIDiscovery - Interface to Google API Discovery Service.

=head1 VERSION

Version 0.23

=cut

use 5.006;
use JSON;
use Data::Dumper;

use WWW::Google::UserAgent;
use WWW::Google::APIDiscovery::API;
use WWW::Google::APIDiscovery::API::MetaData;

use Moo;
use namespace::clean;
extends 'WWW::Google::UserAgent';

our $BASE_URL = 'https://www.googleapis.com/discovery/v1/apis';

has [ qw(apis kind version) ] => (is => 'rw');

=head1 DESCRIPTION

The  Google  APIs  Discovery  Service  allows you to interact with Google APIs by
exposing machine readable metadata about other  Google APIs through a simple API.
Currently supports version v1.

IMPORTANT:The version v1 of the Google APIs Discovery Service is in Labs  and its
features might change unexpectedly until it graduates.

The official Google API document can be found L<here|https://developers.google.com/discovery/v1/getting_started>.

=head1 SYNOPSIS

    use strict; use warnings;
    use WWW::Google::APIDiscovery;

    my $google = WWW::Google::APIDiscovery->new;
    my $apis   = $google->supported_apis;
    my $meta   = $google->discover('customsearch:v1');

    print "Title: ", $meta->title, "\n";

=cut

sub BUILDARGS {
    my ($class, $args) = @_;

    die "ERROR: No parameters required for constructor."
        if defined $args;

    return { api_key => 'Dummy' };
};

sub BUILD {
    my ($self) = @_;

    $self->_supported_apis;
}

=head1 METHODS

=head2 discover()

Returns meta data of the API of type L<WWW::Google::APIDiscovery::API::MetaData>.

=cut

sub discover {
    my ($self, $api_id) = @_;

    die "ERROR: Missing mandatory param: api_id" unless defined $api_id;

    my $api = $self->{apis}->{$api_id};
    die "ERROR: Unsupported API [$api_id]" unless defined $api;

    my $response = $self->get($api->url);
    my $contents = from_json($response->{content});

    return WWW::Google::APIDiscovery::API::MetaData->new($contents);
}

=head2 supported_apis()

Returns the list of supported APIs of type L<WWW::Google::APIDiscovery::API>.

=cut

sub supported_apis {
    my ($self) = @_;

    return $self->{apis};
}

sub _supported_apis {
    my ($self) = @_;

    my $response = $self->get($BASE_URL);
    my $contents = from_json($response->{content});

    $self->kind($contents->{kind});
    $self->version($contents->{discoveryVersion});
    my $supported_apis = {};
    foreach my $item (@{$contents->{items}}) {
        my $id          = $item->{id};
        my $name        = $item->{name};
        my $version     = $item->{version};
        my $title       = $item->{title};
        my $description = $item->{description};
        my $url         = $item->{discoveryRestUrl};
        $supported_apis->{$id} = WWW::Google::APIDiscovery::API->new(
            id          => $id,
            name        => $name,
            version     => $version,
            title       => $title,
            description => $description,
            url         => $url);
    }

    $self->apis($supported_apis);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/WWW-Google-APIDiscovery>

=head1 CONTRIBUTORS

Gabor Szabo (szabgab)

=head1 BUGS

Please  report  any  bugs or feature requests to C<bug-www-google-apidiscovery at
rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Google-APIDiscovery>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Google::APIDiscovery

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Google-APIDiscovery>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Google-APIDiscovery>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Google-APIDiscovery>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Google-APIDiscovery/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2015 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of WWW::Google::APIDiscovery
