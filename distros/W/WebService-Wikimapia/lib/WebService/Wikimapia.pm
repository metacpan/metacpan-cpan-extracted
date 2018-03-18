package WebService::Wikimapia;

$WebService::Wikimapia::VERSION   = '0.13';
$WebService::Wikimapia::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

WebService::Wikimapia - Interface to Wikimapia API.

=head1 VERSION

Version 0.13

=cut

use 5.006;
use JSON;
use Data::Dumper;

use WebService::Wikimapia::UserAgent;
use WebService::Wikimapia::Category;
use WebService::Wikimapia::Place;
use WebService::Wikimapia::Object;
use WebService::Wikimapia::Street;
use WebService::Wikimapia::Params qw($Disable $Format $Pack $FIELDS $Language $Num validate);
use WebService::Wikimapia::UserAgent::Exception;

use Moo;
use namespace::clean;
extends 'WebService::Wikimapia::UserAgent';

has 'base_url' => (is => 'ro', default => sub { return 'http://api.wikimapia.org/'; });
has 'disable'  => (is => 'ro', isa => $Disable);
has 'page'     => (is => 'ro', isa => $Num,      default => sub { return 1;      });
has 'count'    => (is => 'ro', isa => $Num,      default => sub { return 50;     });
has 'language' => (is => 'ro', isa => $Language, default => sub { return 'en';   });
has 'pack'     => (is => 'ro', isa => $Pack,     default => sub { return 'none'; });
has 'format'   => (is => 'ro', isa => $Format,   default => sub { return 'json'; });

=head1 DESCRIPTION

Wikimapia API is a system that allows you to receive data from Wikimapia map  and
that can easily be integrate Wikimapia Geo Data into your  external application /
web site. And it's all free. You need to get the API Key first from L<here|http://wikimapia.org/api?action=create_key>.
Please note API is still in developing stage (beta).

Recent  changes  to  the  API by Wikimapia, marked the method search(), box() and
object() deprecated.

=head1 CONSTRUCTOR

The only key required is 'api_key' which is an api key.Rest of them are optional.

    +----------+----------------------------------------------------------------+
    | Key      | Description                                                    |
    +----------+----------------------------------------------------------------+
    | api_key  | Wikimapia API Key.                                             |
    | page     | This is page number. 1 is default.                             |
    | count    | Determines the number of results/page. 50 is default.          |
    | language | Language in ISO 639-1 format. Default is 'en'.                 |
    +----------+----------------------------------------------------------------+

    use strict; use warnings;
    use WebService::Wikimapia;

    my $key       = 'Your_API_Key';
    my $wikimapia = WebService::Wikimapia->new({ api_key => $api_key });

=head1 LANGUAGE

    +-----------------------+----------------+
    | Language Name         | ISO 639-1 Code |
    +-----------------------+----------------+
    | Abkhaz                |       ab       |
    | Afar                  |       aa       |
    | Afrikaans             |       af       |
    | Akan                  |       ak       |
    | Albanian              |       sq       |
    | Amharic               |       am       |
    | Arabic                |       ar       |
    | Aragonese             |       an       |
    | Armenian              |       hy       |
    | Assamese              |       as       |
    | Avaric                |       av       |
    | Avestan               |       ae       |
    | Aymara                |       ay       |
    | Azerbaijani           |       az       |
    | Bambara               |       bm       |
    | Bashkir               |       ba       |
    | Basque                |       eu       |
    | Belarusian            |       be       |
    | Bengali               |       bn       |
    | Bihari                |       bh       |
    | Bislama               |       bi       |
    | Bosnian               |       bs       |
    | Breton                |       br       |
    | Bulgarian             |       bg       |
    | Burmese               |       my       |
    | Catalan               |       ca       |
    | Chamorro              |       ch       |
    | Chechen               |       ce       |
    | Chichewa              |       ny       |
    | Chinese               |       zh       |
    | Chuvash               |       cv       |
    | Cornish               |       kw       |
    | Corsican              |       co       |
    | Cree                  |       cr       |
    | Croatian              |       hr       |
    | Czech                 |       cs       |
    | Danish                |       da       |
    | Divehi                |       dv       |
    | Dutch                 |       nl       |
    | Dzongkha              |       dz       |
    | English               |       en       |
    | Esperanto             |       eo       |
    | Estonian              |       et       |
    | Ewe                   |       ee       |
    | Faroese               |       fo       |
    | Fijian                |       fj       |
    | Finnish               |       fi       |
    | French                |       fr       |
    | Fula                  |       ff       |
    | Galician              |       gl       |
    | Georgian              |       ka       |
    | German                |       de       |
    | Greek, Modern         |       el       |
    | Guarani               |       gn       |
    | Gujarati              |       gu       |
    | Haitian               |       ht       |
    | Hausa                 |       ha       |
    | Hebrew (modern)       |       he       |
    | Herero                |       hz       |
    | Hindi                 |       hi       |
    | Hiri Motu             |       ho       |
    | Hungarian             |       hu       |
    | Interlingua           |       ia       |
    | Indonesian            |       id       |
    | Interlingue           |       ie       |
    | Irish                 |       ga       |
    | Igbo                  |       ig       |
    | Inupiaq               |       ik       |
    | Ido                   |       io       |
    | Icelandic             |       is       |
    | Italian               |       it       |
    | Inuktitut             |       iu       |
    | Japanese              |       ja       |
    | Javanese              |       jv       |
    | Kalaallisut           |       kl       |
    | Kannada               |       kn       |
    | Kanuri                |       kr       |
    | Kashmiri              |       ks       |
    | Kazaq                 |       kk       |
    | Khmer                 |       km       |
    | Kikuyu                |       ki       |
    | Kinyarwanda           |       rw       |
    | Kirghiz               |       ky       |
    | Komi                  |       kv       |
    | Kongo                 |       kg       |
    | Korean                |       ko       |
    | Kurdish               |       ku       |
    | Kwanyama              |       kj       |
    | Latin                 |       la       |
    | Luxembourgish         |       lb       |
    | Luganda               |       lg       |
    | Limburgish            |       li       |
    | Lingala               |       ln       |
    | Lao                   |       lo       |
    | Lithuanian            |       lt       |
    | Luba-Katanga          |       lu       |
    | Latvian               |       lv       |
    | Manx                  |       gv       |
    | Macedonian            |       mk       |
    | Malagasy              |       mg       |
    | Malay                 |       ms       |
    | Malayalam             |       ml       |
    | Maltese               |       mt       |
    | Ma-ori                |       mi       |
    | Marathi               |       mr       |
    | Marshallese           |       mh       |
    | Mongolian             |       mn       |
    | Nauru                 |       na       |
    | Navajo                |       nv       |
    | Norwegian             |       nb       |
    | North Ndebele         |       nd       |
    | Nepali                |       ne       |
    | Ndonga                |       ng       |
    | Norwegian Nynorsk     |       nn       |
    | Norwegian             |       no       |
    | Nuosu                 |       ii       |
    | South Ndebele         |       nr       |
    | Occitan               |       oc       |
    | Ojibwe                |       oj       |
    | Old Church Slavonic   |       cu       |
    | Oromo                 |       om       |
    | Oriya                 |       or       |
    | Ossetian              |       os       |
    | Punjabi               |       pa       |
    | Pa-li                 |       pi       |
    | Persian               |       fa       |
    | Polish                |       pl       |
    | Pashto                |       ps       |
    | Portuguese            |       pt       |
    | Quechua               |       qu       |
    | Romansh               |       rm       |
    | Kirundi               |       rn       |
    | Romanian              |       ro       |
    | Russian               |       ru       |
    | Sanskrit              |       sa       |
    | Sardinian             |       sc       |
    | Sindhi                |       sd       |
    | Northern Sami         |       se       |
    | Samoan                |       sm       |
    | Sango                 |       sg       |
    | Serbian               |       sr       |
    | Scottish Gaelic;      |       gd       |
    | Shona                 |       sn       |
    | Sinhala               |       si       |
    | Slovak                |       sk       |
    | Slovene               |       sl       |
    | Somali                |       af       |
    | Southern Sotho        |       st       |
    | Spanish               |       es       |
    | Sundanese             |       su       |
    | Swahili               |       sw       |
    | Swati                 |       ss       |
    | Swedish               |       sv       |
    | Tamil                 |       ta       |
    | Telugu                |       te       |
    | Tajik                 |       tg       |
    | Thai                  |       th       |
    | Tigrinya              |       ti       |
    | Tibetan Standard      |       bo       |
    | Turkmen               |       tk       |
    | Tagalog               |       tl       |
    | Tswana                |       tn       |
    | Tonga (Tonga Islands) |       to       |
    | Turkish               |       tr       |
    | Tsonga                |       ts       |
    | Tatar                 |       tt       |
    | Twi                   |       tw       |
    | Tahitian              |       ty       |
    | Uighur                |       ug       |
    | Ukrainian             |       uk       |
    | Urdu                  |       ur       |
    | Uzbek                 |       uz       |
    | Venda                 |       ve       |
    | Vietnamese            |       vi       |
    | Volapuk               |       vo       |
    | Walloon               |       wa       |
    | Welsh                 |       cy       |
    | Wolof                 |       wo       |
    | Western Frisian       |       fy       |
    | Xhosa                 |       xh       |
    | Yiddish               |       yi       |
    | Yoruba                |       yo       |
    | Zhuang                |       za       |
    | Zulu                  |       zu       |
    +-----------------------+----------------+

=head1 METHODS

=head2 place_getbyid()

Returns an object of type L<WebService::Wikimapia::Place>.

    +----------+----------------------------------------------------------------+
    | Key      | Description                                                    |
    +----------+----------------------------------------------------------------+
    | id       | Place Id (required).                                           |
    | language | Language in ISO 639-1 format. Default is 'en'.                 |
    +----------+----------------------------------------------------------------+

    use strict; use warnings;
    use WebService::Wikimapia;

    my $api_key   = 'Your_API_Key';
    my $wikimapia = WebService::Wikimapia->new({ api_key => $api_key });
    my $place     = $wikimapia->place_getbyid({ id => 55 });

    print "Place title: ", $place->title, "\n";

=cut

sub place_getbyid {
    my ($self, $params) = @_;

    my $fields   = { 'id' => 1, 'language' => 0 };
    my $url      = $self->_url('place.getbyid', $fields, $params);
    my $response = $self->get($url);
    my $contents = from_json($response->{content});

    return WebService::Wikimapia::Place->new($contents);
}

=head2 place_getbyarea()

Returns ref to the list of object of type L<WebService::Wikimapia::Place>.

    +----------+----------------------------------------------------------------+
    | Key      | Description                                                    |
    +----------+----------------------------------------------------------------+
    | lon_min  | Longiture Min.                                                 |
    | lat_min  | Latitude Min.                                                  |
    | lon_max  | Longitude Max.                                                 |
    | lat_max  | Latitude Max.                                                  |
    | x        | Tile's x co-ordinate.                                          |
    | y        | Tile's y co-ordinate.                                          |
    | z        | Tile's z co-ordinate.                                          |
    | page     | This is page number. 1 is default.                             |
    | count    | Determines the number of results/page. 50 is default.          |
    | language | Language in ISO 639-1 format. Default is 'en'.                 |
    +----------+----------------------------------------------------------------+

    use strict; use warnings;
    use WebService::Wikimapia;

    my $api_key   = 'Your_API_Key';
    my $wikimapia = WebService::Wikimapia->new({ api_key => $api_key });
    my $places    = $wikimapia->place_getbyarea({
        'lon_min' => 2.292493,
        'lat_min' => 48.8590143,
        'lon_max' => 2.293493,
        'lat_max' => 48.8599143
    });

    print "Place title: ", $places->[0]->title, "\n";

=cut

sub place_getbyarea {
    my ($self, $params) = @_;

    die "ERROR: Missing params list." unless (defined $params);
    die "ERROR: Parameters have to be hash ref" unless (ref($params) eq 'HASH');

    my $fields = {};
    if (exists $params->{'lon_min'}
        || exists $params->{'lat_min'}
        || exists $params->{'lon_max'}
        || exists $params->{'lat_max'}) {
        $fields->{'lon_min'} = 1;
        $fields->{'lat_min'} = 1;
        $fields->{'lon_max'} = 1;
        $fields->{'lat_max'} = 1;
    }
    elsif (exists $params->{'x'}
           || exists $params->{'y'}
           || exists $params->{'z'}) {
        $fields->{'x'} = 1;
        $fields->{'y'} = 1;
        $fields->{'z'} = 1;
    };

    # Optional params
    $fields->{'page'}     = 0;
    $fields->{'count'}    = 0;
    $fields->{'language'} = 0;

    my $url      = $self->_url('place.getbyarea', $fields, $params);
    my $response = $self->get($url);
    my $contents = from_json($response->{content});

    my $places = [];
    foreach my $place (@{$contents->{'places'}}) {
        push @$places, WebService::Wikimapia::Place->new($place);
    }

    return $places;
}

=head2 place_getnearest()

Returns ref to the list of object of type L<WebService::Wikimapia::Place>.

    +----------+----------------------------------------------------------------+
    | Key      | Description                                                    |
    +----------+----------------------------------------------------------------+
    | lon      | Longitude.                                                     |
    | lat      | Latitude.                                                      |
    | count    | Determines the number of results/page. 50 is default.          |
    | language | Language in ISO 639-1 format. Default is 'en'.                 |
    +----------+----------------------------------------------------------------+

    use strict; use warnings;
    use WebService::Wikimapia;

    my $api_key   = 'Your_API_Key';
    my $wikimapia = WebService::Wikimapia->new({ api_key => $api_key });
    my $places    = $wikimapia->place_getnearest({ 'lon' => 2.29451, 'lat' => 48.858252 });

    print "Place title: ", $places->[0]->title, "\n";

=cut

sub place_getnearest {
    my ($self, $params) = @_;

    my $fields   = { 'lat' => 1, 'lon' => 1, 'count' => 0, 'language' => 0 };
    my $url      = $self->_url('place.getnearest', $fields, $params);
    my $response = $self->get($url);
    my $contents = from_json($response->{content});

    my $places = [];
    foreach my $place (@{$contents->{'places'}}) {
        push @$places, WebService::Wikimapia::Place->new($place);
    }

    return $places;
}

=head2 place_search()

Returns ref to the list of object of type L<WebService::Wikimapia::Place>.

    +----------+----------------------------------------------------------------+
    | Key      | Description                                                    |
    +----------+----------------------------------------------------------------+
    | q        | Query to search in wikimapia (UTF-8).                          |
    | lat      | Coordinates of the "search point" lat means latitude.          |
    | lon      | Coordinates of the "search point" lon means longitude.         |
    | page     | This is page number. 1 is default.                             |
    | count    | Determines the number of results/page. 50 is default.          |
    | language | Language in ISO 639-1 format. Default is 'en'.                 |
    +----------+----------------------------------------------------------------+

    use strict; use warnings;
    use WebService::Wikimapia;

    my $api_key   = 'Your_API_Key';
    my $wikimapia = WebService::Wikimapia->new({ api_key => $api_key });
    my $places    = $wikimapia->place_search({ q => 'Recreation', lat => 37.7887088, lon => -122.4997044 });

    print "Place title: ", $places->[0]->title, "\n";

=cut

sub place_search {
    my ($self, $params) = @_;

    my $fields   = { 'q' => 1, 'lat' => 1, 'lon' => 1, 'page' => 0, 'count' => 0, 'language' => 0 };
    my $url      = $self->_url('place.search', $fields, $params);
    my $response = $self->get($url);
    my $contents = from_json($response->{content});

    my $places = [];
    foreach my $place (@{$contents->{'places'}}) {
        push @$places, WebService::Wikimapia::Place->new($place);
    }

    return $places;
}

sub place_update {
    # TODO
}

=head2 street_getbyid()

Returns an object of type L<WebService::Wikimapia::Street>.

    +----------+----------------------------------------------------------------+
    | Key      | Description                                                    |
    +----------+----------------------------------------------------------------+
    | id       | Street Id (required).                                          |
    | language | Language in ISO 639-1 format. Default is 'en'.                 |
    +----------+----------------------------------------------------------------+

    use strict; use warnings;
    use WebService::Wikimapia;

    my $api_key   = 'Your_API_Key';
    my $wikimapia = WebService::Wikimapia->new({ api_key => $api_key });
    my $street    = $wikimapia->street_getbyid({ id => 1 });

    print "Street title: ", $street->title, "\n";

=cut

sub street_getbyid {
    my ($self, $params) = @_;

    my $fields   = { 'id' => 1, 'language' => 0 };
    my $url      = $self->_url('street.getbyid', $fields, $params);
    my $response = $self->get($url);
    my $contents = from_json($response->{content});

    return WebService::Wikimapia::Street->new($contents);
}

=head2 category_getbyid()

Returns an object of type L<WebService::Wikimapia::Category>.

    +----------+----------------------------------------------------------------+
    | Key      | Description                                                    |
    +----------+----------------------------------------------------------------+
    | id       | Category Id (required).                                        |
    | language | Language in ISO 639-1 format. Default is 'en'.                 |
    +----------+----------------------------------------------------------------+

    use strict; use warnings;
    use WebService::Wikimapia;

    my $api_key   = 'Your_API_Key';
    my $wikimapia = WebService::Wikimapia->new({ api_key => $api_key });
    my $category  = $wikimapia->category_getbyid({  id => 203 });

    print "Category name: ", $category->name, "\n";

=cut

sub category_getbyid {
    my ($self, $params) = @_;

    my $fields   = { 'id' => 1, 'language' => 0 };
    my $url      = $self->_url('category.getbyid', $fields, $params);
    my $response = $self->get($url);
    my $contents = from_json($response->{content});

    return WebService::Wikimapia::Category->new($contents->{'category'});
}

=head2 category_getall()

Returns ref to the list of object of type L<WebService::Wikimapia::Category>.

    +----------+----------------------------------------------------------------+
    | Key      | Description                                                    |
    +----------+----------------------------------------------------------------+
    | page     | This is page number. 1 is default.                             |
    | count    | Determines the number of results/page. 50 is default.          |
    | language | Language in ISO 639-1 format. Default is 'en'.                 |
    +----------+----------------------------------------------------------------+

    use strict; use warnings;
    use WebService::Wikimapia;

    my $api_key    = 'Your_API_Key';
    my $wikimapia  = WebService::Wikimapia->new({ api_key => $api_key });
    my $categories = $wikimapia->category_getall;

    print "Category name: ", $categories->[0]->name, "\n";

=cut

sub category_getall {
    my ($self, $params) = @_;

    my ($url);
    if (defined $params) {
        my $fields = { 'page' => 0, 'count' => 0, 'language' => 0 };
        $url = $self->_url('category.getall', $fields, $params);
    }
    else {
        $url = $self->_url('category.getall');
    }

    my $response = $self->get($url);
    my $contents = from_json($response->{content});

    my $categories = [];
    foreach my $category (@{$contents->{categories}}) {
        push @$categories, WebService::Wikimapia::Category->new($category);
    }

    return $categories;
}

=head2 search() [DEPRECATED]

Returns ref to the list object of type L<WebService::Wikimapia::Place>.

    +-----+---------------------------------------------------------------------+
    | Key | Description                                                         |
    +-----+---------------------------------------------------------------------+
    | q   | Query to search in wikimapia (UTF-8).                               |
    | lat | Coordinates of the "search point" lat means latitude.               |
    | lon | Coordinates of the "search point" lon means longitude.              |
    +-----+---------------------------------------------------------------------+

    use strict; use warnings;
    use WebService::Wikimapia;

    my $api_key   = 'Your_API_Key';
    my $wikimapia = WebService::Wikimapia->new({ api_key => $api_key });
    my $places    = $wikimapia->search({ q => 'Recreation', lat => 37.7887088, lon => -122.4997044 });

    print "Place name: ", $places->[0]->name, "\n";

=cut

sub search {
    my ($self, $params) = @_;

    print {*STDERR} "WARNING: Deprecated method search(), please refer the perldoc.\n";
    my $fields   = { 'q' => 1, 'lat' => 1, 'lon' => 1 };
    my $url      = $self->_url('search', $fields, $params);
    my $response = $self->get($url);
    my $contents = from_json($response->{content});

    my $places = [];
    foreach my $place (@{$contents->{'folder'}}) {
        push @$places, WebService::Wikimapia::Place->new($place);
    }

    return $places;
}

=head2 box() [DEPRECATED]

Returns ref to the list of object of type L<WebService::Wikimapia::Place>.

    +---------+-------------------------------------------------------------------+
    | Key     | Description                                                       |
    +---------+-------------------------------------------------------------------+
    | bbox    | Coordinates of the selected box [lon_min,lat_min,lon_max,lat_max].|
    | lon_min | Longiture Min.                                                    |
    | lat_min | Latitude Min.                                                     |
    | lon_max | Longitude Max.                                                    |
    | lat_max | Latitude Max.                                                     |
    | x       | Tile's x co-ordinate.                                             |
    | y       | Tile's y co-ordinate.                                             |
    | z       | Tile's z co-ordinate.                                             |
    +---------+-------------------------------------------------------------------+

    use strict; use warnings;
    use WebService::Wikimapia;

    my $api_key   = 'Your_API_Key';
    my $wikimapia = WebService::Wikimapia->new({ api_key => $api_key });
    my $places    = $wikimapia->box({ bbox => '37.617188,55.677586,37.70507,55.7271128' });

    print "Place name: ", $places->[0]->name, "\n";

=cut

sub box {
    my ($self, $params) = @_;

    print {*STDERR} "WARNING: Deprecated method box(), please refer the perldoc.\n";
    die "ERROR: Missing params list." unless (defined $params);
    die "ERROR: Parameters have to be hash ref" unless (ref($params) eq 'HASH');

    my $fields = {};
    if (exists $params->{bbox}) {
        $fields->{'bbox'} = 1;
    }
    else {
        $fields->{'lon_min'} = 1;
        $fields->{'lon_max'} = 1;
        $fields->{'lat_min'} = 1;
        $fields->{'lat_max'} = 1;
        $fields->{'x'} = 1;
        $fields->{'y'} = 1;
        $fields->{'z'} = 1;
    }

    my $url      = $self->_url('box', $fields, $params);
    my $response = $self->get($url);
    my $contents = from_json($response->{content});

    my $places = [];
    foreach my $content (@{$contents->{folder}}) {
        push @$places, WebService::Wikimapia::Place->new($content);
    }

    return $places;
}

=head2 object() [DEPRECATED]

Returns an object of type L<WebService::Wikimapia::Object>.

    +---------+-----------------------------------------------------------------+
    | Key     | Description                                                     |
    +---------+-----------------------------------------------------------------+
    | id      | Identifier of the object you want to get information about.     |
    +---------+-----------------------------------------------------------------+

    use strict; use warnings;
    use WebService::Wikimapia;

    my $api_key   = 'Your_API_Key';
    my $wikimapia = WebService::Wikimapia->new({ api_key => $api_key });
    my $object    = $wikimapia->object(22139);

    print "Title: ", $object->title, "\n";

=cut

sub object {
    my ($self, $id) = @_;

    print {*STDERR} "WARNING: Deprecated method object(), please refer the perldoc.\n";
    my $fields   = { 'id' => 1 };
    my $params   = { 'id' => $id };
    my $url      = $self->_url('object', $fields, $params);
    my $response = $self->get($url);
    my $contents = from_json($response->{content});

    return WebService::Wikimapia::Object->new($contents);
}

#
#
# PRIVATE METHODS

sub _url {
    my ($self, $function, $fields, $params) = @_;

    validate($fields, $params);

    my $url = sprintf("%s?function=%s&key=%s&format=%s", $self->base_url, $function, $self->api_key, $self->format);

    if (defined $params && defined $fields) {
        foreach my $key (keys %$fields) {
            my $_key = "&$key=%" . $FIELDS->{$key}->{type};
            $url .= sprintf($_key, $params->{$key}) if defined $params->{$key};
        }
    }

    foreach my $key (keys %$fields) {
        if (!exists $params->{$key} && !$fields->{$key}) {
            my $_key = "&$key=%" . $FIELDS->{$key}->{type};
            $url .= sprintf($_key, $self->{$key});
        }
    }

    return $url;
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/WebService-Wikimapia>

=head1 BUGS

Please  report  any  bugs  or feature  requests to C<bug-webservice-wikimapia  at
rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Wikimapia>.
I will be notified and then you'll automatically be notified of  progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Wikimapia

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Wikimapia>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Wikimapia>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Wikimapia>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Wikimapia/>

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

1; # End of WebService::Wikimapia
