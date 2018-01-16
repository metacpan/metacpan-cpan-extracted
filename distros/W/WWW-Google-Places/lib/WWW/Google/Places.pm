package WWW::Google::Places;

$WWW::Google::Places::VERSION   = '0.33';
$WWW::Google::Places::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

WWW::Google::Places - Interface to Google Places API.

=head1 VERSION

Version 0.33

=cut

use 5.006;
use JSON;
use Data::Dumper;

use WWW::Google::UserAgent;
use WWW::Google::UserAgent::DataTypes qw(:all);
use WWW::Google::Places::Params qw(get_validator);
use WWW::Google::Places::SearchResult;
use WWW::Google::Places::DetailResult;

use Moo;
use namespace::clean;
extends 'WWW::Google::UserAgent';

our $BASE_URL = 'https://maps.googleapis.com/maps/api/place';

has 'sensor'    => (is => 'ro', isa => TrueFalse, default => sub { 'false' });
has 'output'    => (is => 'ro', isa => FileType,  default => sub { 'json'  });
has 'language'  => (is => 'ro', isa => Language,  default => sub { 'en'    });
has 'validator' => (is => 'ro', default => \&get_validator);

before [qw/search paged_search add/] => sub {
    my ($self, $param) = @_;

    my $method = (caller(1))[3];
    $method =~ /(.*)\:\:(.*)$/;
    $self->validator->validate($2, $param);
};

=head1 DESCRIPTION

The Google Places API is a service that returns information about Places, defined
within  this  API  as establishments,  geographic location or prominent points of
interest using HTTP request.Place requests specify location as latitude/longitude
coordinates. Users with an API key are allowed 1,000 requests per 24 hour period.
Currently it supports version v3.

The official Google API document can be found L<here|https://developers.google.com/places/webservice/intro>.

=head1 SYNOPSIS

    use strict; use warnings;
    use WWW::Google::Places;

    my $api_key = 'YOUR_API_KEY';
    my $place   = WWW::Google::Places->new({ api_key => $api_key });

    # Google search place
    my $results = $place->search({ location => '-33.8670522,151.1957362', radius => 500 });
    print join("\n----------------------------------------\n", @$results), "\n";

    # Google search place details
    my $place_id = 'ChIJ1ZL9NkGuEmsRUEkzFmh9AQU';
    print "\n----------------------------------------\n";
    print $place->details($place_id), "\n";

=head1 PLACE TYPES

Supported types for Place adds/searches.

    +---------------------------------+
    | accounting                      |
    | airport                         |
    | amusement_park                  |
    | aquarium                        |
    | art_gallery                     |
    | atm                             |
    | bakery                          |
    | bank                            |
    | bar                             |
    | beauty_salon                    |
    | bicycle_store                   |
    | book_store                      |
    | bowling_alley                   |
    | bus_station                     |
    | cafe                            |
    | campground                      |
    | car_dealer                      |
    | car_rental                      |
    | car_repair                      |
    | car_wash                        |
    | casino                          |
    | cemetery                        |
    | church                          |
    | city_hall                       |
    | clothing_store                  |
    | convenience_store               |
    | courthouse                      |
    | dentist                         |
    | department_store                |
    | doctor                          |
    | electrician                     |
    | electronics_store               |
    | embassy                         |
    | establishment                   |
    | finance                         |
    | fire_station                    |
    | florist                         |
    | food                            |
    | funeral_home                    |
    | furniture_store                 |
    | gas_station                     |
    | general_contractor              |
    | geocode                         |
    | grocery_or_supermarket          |
    | gym                             |
    | hair_care                       |
    | hardware_store                  |
    | health                          |
    | hindu_temple                    |
    | home_goods_store                |
    | hospital                        |
    | insurance_agency                |
    | jewelry_store                   |
    | laundry                         |
    | lawyer                          |
    | library                         |
    | liquor_store                    |
    | local_government_office         |
    | locksmith                       |
    | lodging                         |
    | meal_delivery                   |
    | meal_takeaway                   |
    | mosque                          |
    | movie_rental                    |
    | movie_theater                   |
    | moving_company                  |
    | museum                          |
    | night_club                      |
    | painter                         |
    | park                            |
    | parking                         |
    | pet_store                       |
    | pharmacy                        |
    | physiotherapist                 |
    | place_of_worship                |
    | plumber                         |
    | police                          |
    | post_office                     |
    | real_estate_agency              |
    | restaurant                      |
    | roofing_contractor              |
    | rv_park                         |
    | school                          |
    | shoe_store                      |
    | shopping_mall                   |
    | spa                             |
    | stadium                         |
    | storage                         |
    | store                           |
    | subway_station                  |
    | synagogue                       |
    | taxi_stand                      |
    | train_station                   |
    | travel_agency                   |
    | university                      |
    | veterinary_care                 |
    | zoo                             |
    +---------------------------------+

Additional types listed below can be used in Place Searches, but not when adding a Place.

    +---------------------------------+
    | administrative_area_level_1     |
    | administrative_area_level_2     |
    | administrative_area_level_3     |
    | colloquial_area                 |
    | country                         |
    | floor                           |
    | intersection                    |
    | locality                        |
    | natural_feature                 |
    | neighborhood                    |
    | political                       |
    | point_of_interest               |
    | post_box                        |
    | postal_code                     |
    | postal_code_prefix              |
    | postal_town                     |
    | premise                         |
    | room                            |
    | route                           |
    | street_address                  |
    | street_number                   |
    | sublocality                     |
    | sublocality_level_4             |
    | sublocality_level_5             |
    | sublocality_level_3             |
    | sublocality_level_2             |
    | sublocality_level_1             |
    | subpremise                      |
    | transit_station                 |
    +---------------------------------+

=head1 LANGUAGES

    +-------+-------------------------+
    | Code  | Name                    |
    +-------+-------------------------+
    | ar    | ARABIC                  |
    | eu    | BASQUE                  |
    | bg    | BULGARIAN               |
    | bn    | BENGALI                 |
    | ca    | CATALAN                 |
    | cs    | CZECH                   |
    | da    | DANISH                  |
    | de    | GERMAN                  |
    | el    | GREEK                   |
    | en    | ENGLISH                 |
    | en-AU | ENGLISH (AUSTRALIAN)    |
    | en-GB | ENGLISH (GREAT BRITAIN) |
    | es    | SPANISH                 |
    | eu    | BASQUE                  |
    | fa    | FARSI                   |
    | fi    | FINNISH                 |
    | fil   | FILIPINO                |
    | fr    | FRENCH                  |
    | gl    | GALICIAN                |
    | gu    | GUJARATI                |
    | hi    | HINDI                   |
    | hr    | CROATIAN                |
    | hu    | HUNGARIAN               |
    | id    | INDONESIAN              |
    | it    | ITALIAN                 |
    | iw    | HEBREW                  |
    | ja    | JAPANESE                |
    | kn    | KANNADA                 |
    | ko    | KOREAN                  |
    | lt    | LITHUANIAN              |
    | lv    | LATVIAN                 |
    | ml    | MALAYALAM               |
    | mr    | MARATHI                 |
    | nl    | DUTCH                   |
    | no    | NORWEGIAN               |
    | pl    | POLISH                  |
    | pt    | PORTUGUESE              |
    | pt-BR | PORTUGUESE (BRAZIL)     |
    | pt-PT | PORTUGUESE (PORTUGAL)   |
    | ro    | ROMANIAN                |
    | ru    | RUSSIAN                 |
    | sk    | SLOVAK                  |
    | sl    | SLOVENIAN               |
    | sr    | SERBIAN                 |
    | sv    | SWEDISH                 |
    | tl    | TAGALOG                 |
    | ta    | TAMIL                   |
    | te    | TELUGU                  |
    | th    | THAI                    |
    | tr    | TURKISH                 |
    | uk    | UKRAINIAN               |
    | vi    | VIETNAMESE              |
    | zh-CN | CHINESE (SIMPLIFIED)    |
    | zh-TW | CHINESE (TRADITIONAL)   |
    +-------+-------------------------+

=head1 CONSTRUCTOR

The constructor expects the following keys. Only the  'api_key'  is mandatory and
others are optionals.

    +-----------+---------------------------------------------------------------+
    | Parameter | Description                                                   |
    +-----------+---------------------------------------------------------------+
    | api_key   | Your application API key. You should supply a valid API key   |
    |           | with all requests. Get a key from the Google APIs console.    |
    |           | This must be provided.                                        |
    | sensor    | Indicates whether or not the Place request came from a device |
    |           | using a location sensor (e.g. a GPS) to determine the location|
    |           | sent in this request. This value must be either true or false.|
    |           | Default is false.                                             |
    | language  | The language code, indicating in which language the results   |
    |           | should be returned. The default is en.                        |
    +-----------+---------------------------------------------------------------+

    use strict; use warnings;
    use WWW::Google::Places;

    my $api_key = 'Your_API_Key';
    my $place   = WWW::Google::Places->new({ api_key => $api_key });

=head1 METHODS

=head2 search(\%params)

It expects a ref to hash as the only parameter  containing the following keys. It
returns list  of  objects  of type L<WWW::Google::Places::SearchResult> in a LIST
context and ref to the same list in a SCALAR context.

    +----------+----------------------------------------------------------------+
    | Key      | Description                                                    |
    +----------+----------------------------------------------------------------+
    | location | The latitude/longitude around which to retrieve Place          |
    |          | information. This must be provided as a google.maps.LatLng     |
    |          | object. This must be provided.                                 |
    | radius   | The distance (in meters) within which to return Place results. |
    |          | The recommended best practice is to set radius based on the    |
    |          | accuracy of the location signal as given by the location       |
    |          | sensor. Note that setting a radius biases result to the        |
    |          | indicated area, but may not fully restrict results to the      |
    |          | specified area. This must be provided.                         |
    | types    | Restricts the results to Places matching at least one of the   |
    |          | specified types. Types should be separated with a pipe symbol. |
    | name     | A term to be matched against the names of Places.              |
    +----------+----------------------------------------------------------------+

    use strict; use warnings;
    use WWW::Google::Places;

    my $api_key = 'Your_API_Key';
    my $place   = WWW::Google::Places->new({ api_key => $api_key });
    my $results = $place->search({ location=>'-33.8670522,151.1957362', radius=>500 });

=cut

sub search {
    my ($self, $values) = @_;

    my $url = $self->_url('search');
    $url .= $self->validator->query_param('search', $values);
    my $response = $self->get($url);
    my $contents = from_json($response->{content});

    my @results  = map { WWW::Google::Places::SearchResult->new($_) } @{$contents->{results}};
    return wantarray ? @results : \@results;
}

=head2 paged_search(\%params)

Accepts the  same  values  as C<search(\%params)> but  handles  queries that have
multiple  pages worth of data. Using paged_search the max number of results is 60
(or 3 pages worth) L<https://developers.google.com/places/documentation/search#PlaceSearchRequests>

It returns list of objects of type L<WWW::Google::Places::SearchResult> in a LIST
context and ref to a list in a SCALAR context.

NOTE:Due to the way that Google handles the paging of results there is a required
sleep of 2 seconds between each requests so that the Google pageTokens can become
active.

    use strict; use warnings;
    use WWW::Google::Places;

    my $api_key = 'Your_API_Key';
    my $place   = WWW::Google::Places->new({ api_key => $api_key });
    my $results = $place->paged_search(
                  { location => '34.0522222,-118.2427778',
                    radius   => 500,
                    types    => 'bar|restaurant',
                  });

=cut

sub paged_search {
    my ($self, $values) = @_;

    my ($pagetoken, $contents, $search_results);
    do {
       if (defined $pagetoken) {
          $values->{pagetoken} = $pagetoken;
          # pagetokens take a few seconds to become active
          sleep(2);
       }

       my $url = $self->_url('search');
       $url .= $self->validator->query_param('paged_search', $values);
       my $response = $self->get($url);
       $contents    = from_json( $response->{content} );

       push @$search_results,
          map { WWW::Google::Places::SearchResult->new($_) } @{$contents->{results}};
    } while $pagetoken = $contents->{next_page_token};

    return wantarray ? @$search_results : $search_results;
}

=head2 details($place_id)

Expects place id, a textual identifier that uniquely identifies a place, returned
from a Place Search. It then returns an object of type L<WWW::Google::Places::DetailResult>.

    use strict; use warnings;
    use WWW::Google::Places;

    my $api_key = 'Your_API_Key';
    my $placeid = 'Place_ID';
    my $place   = WWW::Google::Places->new({ api_key => $api_key });
    my $details = $place->details($placeid);

=cut

sub details {
    my ($self, $placeid) = @_;

    my $values = { placeid => $placeid };
    $self->validator->validate('details', $values);
    my $url = $self->_url('details');
    $url .= $self->validator->query_param('details', $values);

    my $response = $self->get($url);
    my $contents = from_json($response->{content});

    return WWW::Google::Places::DetailResult->new($contents->{result});
}

=head2 add(\%params)

Expects a ref to hash as the only parameter containing the following keys.It then
returns place id.

    +----------+----------------------------------------------------------------+
    | Key      | Description                                                    |
    +----------+----------------------------------------------------------------+
    | location | The latitude/longitude around which to retrieve Place          |
    |          | information. This must be provided as a google.maps.LatLng     |
    |          | object.                                                        |
    | accuracy | The accuracy of the location signal on which this request is   |
    |          | based, expressed in meters. This must be provided.             |
    | name     | The full text name of the Place.                               |
    | types    | Restricts the results to Places matching at least one of the   |
    |          | specified types. Types should be separated with a pipe symbol. |
    +----------+----------------------------------------------------------------+

    use strict; use warnings;
    use WWW::Google::Places;

    my $api_key = 'Your_API_Key';
    my $place   = WWW::Google::Places->new({ api_key => $api_key });
    my $status  = $place->add({ 'location'=>'-33.8669710,151.1958750', accuracy=>40, name=>'Google Shoes!' });

=cut

sub add {
    my ($self, $values) = @_;

    my $params   = $self->validator->get_method('add')->fields;
    my $url      = $self->_url('add');
    my $content  = $self->_content($params, $values);
    my $headers  = { 'Host' => 'maps.googleapis.com' };
    my $response = $self->post($url, $headers, $content);
    my $contents = from_json($response->{content});

    return $contents->{place_id};
}

=head2 delete($place_id)

Expects place id, a textual identifier that uniquely identifies a place, returned
from a Place Search.

Delete a place as given reference. Place can  be  deleted by the same application
that has added it in the first place.Once moderated and added into the full Place
Search results, a Place  can  no longer  be deleted. Places that are not accepted
by  the  moderation  process  will continue to be visible to the application that
submitted them.

    use strict; use warnings;
    use WWW::Google::Places;

    my $api_key  = 'Your_API_Key';
    my $place_id = 'Place_ID';
    my $place    = WWW::Google::Places->new({ api_key => $api_key });
    my $status   = $place->delete($place_id);

=cut

sub delete {
    my ($self, $place_id) = @_;

    my $values   = { place_id => $place_id };
    $self->validator->validate('delete', $values);
    my $params   = $self->validator->get_method('delete')->fields;
    my $url      = $self->_url('delete');
    my $content  = $self->_content($params, $values);
    my $headers  = { 'Host' => 'maps.googleapis.com' };
    my $response = $self->post($url, $headers, $content);

    return from_json($response->{content});
}

=head2 search_place(%params) *** DEPRECATED ***

Instead call method search().

Returns a list of objects of type L<WWW::Google::Places::SearchResult>.

=cut

sub search_place {
    my ($self, %values) = @_;

    warn "DEPRECATED method, please use search()";
    $self->search(\%values);
}

=head2 place_detail($reference) *** DEPRECATED ***

Instead call method details().

Returns an object of type L<WWW::Google::Places::DetailResult>.

=cut

sub place_detail {
    my ($self, $reference) = @_;

    warn "DEPRECATED method, please use details(). Also key 'reference' is deprecated, use placeid";

    my $values   = { reference => $reference };
    $self->validator->validate('place_detail', $values);
    my $params   = $self->validator->get_method('place_detail')->fields;
    my $url      = $self->_url('details');
    $url .= $self->validator->query_param('place_detail', $values);
    my $response = $self->get($url);
    my $contents = from_json($response->{content});

    return WWW::Google::Places::DetailResult->new($contents->{result});
}

=head2 add_place(%params) *** DEPRECATED ***

Instead call method add().

Returns an object of type L<WWW::Google::Places::DetailResult>.

=cut

sub add_place {
    my ($self, %values) = @_;

    warn "DEPRECATED method, please use add()";
    $self->add(\%values);
}

=head2 delete_place($reference) *** DEPRECATED ***

Instead call method delete().

=cut

sub delete_place {
    my ($self, $reference) = @_;

    warn "DEPRECATED method, please use delete(). Also key 'reference' is deprecated, use place_id";
    my $values   = { reference => $reference };
    $self->validator->validate('delete_place', $values);
    my $params   = $self->validator->get_method('delete_place')->fields;
    my $url      = $self->_url('delete');
    my $content  = $self->_content($params, $values);
    my $headers  = { 'Host' => 'maps.googleapis.com' };
    my $response = $self->post($url, $headers, $content);

    return from_json($response->{content});
}

=head2 place_checkins() *** UNSUPPORTED ***

=cut

sub place_checkins {
    warn "Google API no longer supports the feature."
}

#
#
# PRIVATE METHODS

sub _url {
    my ($self, $type) = @_;

    return sprintf("%s/%s/%s?key=%s&sensor=%s&language=%s",
                   $BASE_URL, $type, $self->output, $self->api_key,
                   $self->sensor, $self->language);
}

sub _content {
    my ($self, $params, $values) = @_;

    my $data = {};
    foreach my $key (keys %$params) {
        if ($key eq 'language') {
            if (defined $values->{$key}) {
                $data->{$key} = $values->{$key};
            }
            else {
                $data->{$key} = $self->language;
            }
        }

        next unless defined $values->{$key};

        if ($key eq 'location') {
            my ($lat, $lng) = split /\,/, $values->{$key};
            $data->{$key} = {'lat' => _handle_number($lat), 'lng' => _handle_number($lng)};
        }
        elsif ($key eq 'types') {
            $data->{$key} = [ $values->{$key} ];
        }
        elsif ($self->validator->get_field($key)->format eq 'd') {
            $data->{$key} = _handle_number($values->{$key});
        }
        else {
            $data->{$key} = $values->{$key};
        }
    };

    return to_json($data);
}

sub _handle_number {
    my ($number) = @_;

    return ($number =~ m/^\-?[\d]+(\.[\d]+)?$/)?($number*1):$number;
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/WWW-Google-Places>

=head1 CONTRIBUTORS

=over 4

=item * Hunter McMillen (mcmillhj)

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-google-places at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Google-Places>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Google::Places

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Google-Places>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Google-Places>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Google-Places>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Google-Places/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2016 Mohammad S Anwar.

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

1; # End of WWW::Google::Places
