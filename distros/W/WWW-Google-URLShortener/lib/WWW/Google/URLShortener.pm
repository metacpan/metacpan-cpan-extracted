package WWW::Google::URLShortener;

$WWW::Google::URLShortener::VERSION = '0.19';

=head1 NAME

WWW::Google::URLShortener - Interface to Google URL Shortener API.

=head1 VERSION

Version 0.19

=cut

use 5.006;
use JSON;
use Data::Dumper;

use WWW::Google::UserAgent;
use WWW::Google::URLShortener::Params qw(validate);
use WWW::Google::URLShortener::Analytics;
use WWW::Google::URLShortener::Analytics::Result;
use WWW::Google::URLShortener::Analytics::Result::Country;
use WWW::Google::URLShortener::Analytics::Result::Browser;
use WWW::Google::URLShortener::Analytics::Result::Referrer;
use WWW::Google::URLShortener::Analytics::Result::Platform;

use Moo;
use namespace::clean;
extends 'WWW::Google::UserAgent';

our $BASE_URL = 'https://www.googleapis.com/urlshortener/v1/url';

=head1 DESCRIPTION

The Google URL Shortener at goo.gl is a service that takes long URLs and squeezes
them into fewer characters to make a link that is easier to share, tweet or email
to friends. Currently it supports version v1.

The official Google API document can be found L<here|https://developers.google.com/url-shortener/v1/getting_started>.

IMPORTANT: The version v1 of Google URL Shortener API is in Labs and its features
might change unexpectedly until it graduates.

=head1 CONSTRUCTOR

The constructor expects your application API, get it for FREE from Google.

    use strict; use warnings;
    use WWW::Google::URLShortener;

    my $api_key = 'Your_API_Key';
    my $google  = WWW::Google::URLShortener->new({ api_key => $api_key });

=head1 METHODS

=head2 shorten_url()

Returns the shorten url for the given long url as provided by Google URL Shortener
API. This method expects one scalar parameter i.e. the long url.

    use strict; use warnings;
    use WWW::Google::URLShortener;

    my $api_key = 'Your_API_Key';
    my $google  = WWW::Google::URLShortener->new({ api_key => $api_key });
    print $google->shorten_url('http://www.google.com');

=cut

sub shorten_url {
    my ($self, $long_url) = @_;

    validate({ longUrl => 1 }, { longUrl => $long_url });

    my $url      = sprintf("%s?key=%s", $BASE_URL, $self->api_key);
    my $headers  = { 'Content-Type' => 'application/json' };
    my $content  = to_json({ longUrl => $long_url });
    my $response = $self->post($url, $headers, $content);
    my $contents = from_json($response->{content});

    return $contents->{id};
}

=head2 expand_url()

Returns the expaned url for the given long url as provided by Google URL Shortener
API. This method expects one scalar parameter i.e. the short url.

    use strict; use warnings;
    use WWW::Google::URLShortener;

    my $api_key = 'Your_API_Key';
    my $google  = WWW::Google::URLShortener->new({ api_key => $api_key });
    print $google->expand_url('http://goo.gl/fbsS');

=cut

sub expand_url {
    my ($self, $short_url) = @_;

    validate({ shortUrl => 1 }, { shortUrl => $short_url });

    my $url      = sprintf("%s?key=%s&shortUrl=%s", $BASE_URL, $self->api_key, $short_url);
    my $response = $self->get($url);
    my $content  = from_json($response->{content});

    return $content->{longUrl};
}

=head2 get_analytics()

Returns the object of L<WWW::Google::URLShortener::Analytics>.

    use strict; use warnings;
    use WWW::Google::URLShortener;

    my $api_key   = 'Your_API_Key';
    my $google    = WWW::Google::URLShortener->new({ api_key => $api_key });
    my $analytics = $google->get_analytics('http://goo.gl/fbsS');

=cut

sub get_analytics {
    my ($self, $short_url) = @_;

    validate({ shortUrl => 1 }, { shortUrl => $short_url });

    my $url      = sprintf("%s?key=%s&shortUrl=%s&projection=FULL", $BASE_URL, $self->api_key, $short_url);
    my $response = $self->get($url);
    my $content  = from_json($response->{content});

    return _analytics($content);
}

sub _analytics {
    my ($data) = @_;

    my $results = [];
    foreach my $type (keys %{$data->{analytics}}) {

        my $countries = [];
        foreach my $country (@{$data->{analytics}->{$type}->{countries}}) {
            push @$countries, WWW::Google::URLShortener::Analytics::Result::Country->new($country);
        }

        my $platforms = [];
        foreach my $platform (@{$data->{analytics}->{$type}->{platforms}}) {
            push @$platforms, WWW::Google::URLShortener::Analytics::Result::Platform->new($platform);
        }

        my $browsers = [];
        foreach my $browser (@{$data->{analytics}->{$type}->{browsers}}) {
            push @$browsers, WWW::Google::URLShortener::Analytics::Result::Browser->new($browser);
        }

        my $referrers = [];
        foreach my $referrer (@{$data->{analytics}->{$type}->{referrers}}) {
            push @$referrers, WWW::Google::URLShortener::Analytics::Result::Referrer->new($referrer);
        }

        push @$results,
        WWW::Google::URLShortener::Analytics::Result->new(
            type           => $type,
            shortUrlClicks => $data->{analytics}->{$type}->{shortUrlClicks},
            longUrlClicks  => $data->{analytics}->{$type}->{longUrlClicks},
            countries      => $countries,
            referrers      => $referrers,
            browsers       => $browsers,
            platforms      => $platforms );
    }

    return WWW::Google::URLShortener::Analytics->new(
        id      => $data->{id},
        longUrl => $data->{longUrl},
        created => $data->{created},
        kind    => $data->{kind},
        result  => $results );
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/Manwar/WWW-Google-URLShortener>

=head1 BUGS

Please  report  any bugs  or feature requests to C<bug-www-google-urlshortener at
rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Google-URLShortener>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Google::URLShortener

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Google-URLShortener>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Google-URLShortener>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Google-URLShortener>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Google-URLShortener/>

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

1; # End of WWW::Google::URLShortener
