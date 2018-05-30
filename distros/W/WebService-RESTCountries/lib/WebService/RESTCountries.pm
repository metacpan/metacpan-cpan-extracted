package WebService::RESTCountries;

use utf8;
use Moo;
use Types::Standard qw(Str ArrayRef);
use strictures 2;
use namespace::clean;

with 'Role::REST::Client';

our $VERSION = '0.2';

has api_url => (
    isa => Str,
    is => 'rw',
    default => sub { 'https://restcountries.eu/rest/v2/' },
);

has fields => (
    isa => ArrayRef[Str],
    is => 'rw',
    default => sub { [] },
);

sub BUILD {
    my ($self) = @_;

    $self->set_persistent_header('User-Agent' => __PACKAGE__ . q| |
          . ($WebService::RESTCountries::VERSION || q||));
    $self->server($self->api_url);

    return $self;
}

sub ping {
    my ($self) = @_;

    my $response = $self->user_agent->request('HEAD', $self->api_url);

    return ($response->code == 200) ? 1 : 0;
}

sub search_all {
    my ($self) = @_;

    return $self->_request('all');
}

sub search_by_country_name {
    my ($self, $name) = @_;

    utf8::encode($name);

    return $self->_request(qq|name/$name|);
}

sub search_by_country_full_name {
    my ($self, $full_name) = @_;

    utf8::encode($full_name);

    my $result = $self->_request(qq|name/$full_name|, {fullText => 'true'});

    return (ref $result eq 'ARRAY') ? $result->[0] : $result;
}

sub search_by_country_code {
    my ($self, $country_code) = @_;

    $country_code = lc($country_code);

    my $result = $self->_request(qq|alpha/$country_code|);

    return (ref $result eq 'ARRAY') ? $result->[0] : $result;
}

sub search_by_country_codes {
    my ($self, $country_codes) = @_;

    my @lowercase_country_codes = map { lc } @$country_codes;

    my $query = {
        codes => join(';', @lowercase_country_codes)
    };

    my $result = $self->_request(qq|alpha|, $query);

    return $result if (defined $result->[0]);

    return;
}

sub search_by_currency {
    my ($self, $currency) = @_;

    $currency = lc($currency);

    my $result = $self->_request(qq|currency/$currency|);

    return (ref $result eq 'ARRAY') ? $result->[0] : $result;
}

sub search_by_language_code {
    my ($self, $language_code) = @_;

    $language_code = lc($language_code);

    return $self->_request(qq|lang/$language_code|);
}

sub search_by_capital_city {
    my ($self, $capital_city) = @_;

    utf8::encode($capital_city);

    my $result = $self->_request(qq|capital/$capital_city|);

    return (ref $result eq 'ARRAY') ? $result->[0] : $result;
}

sub search_by_calling_code {
    my ($self, $calling_code) = @_;

    my $result = $self->_request(qq|callingcode/$calling_code|);

    return (ref $result eq 'ARRAY') ? $result->[0] : $result;
}

sub search_by_region {
    my ($self, $region) = @_;

    $region = lc($region);

    return $self->_request(qq|region/$region|);
}

sub search_by_regional_bloc {
    my ($self, $regional_bloc) = @_;

    $regional_bloc = lc($regional_bloc);

    return $self->_request(qq|regionalbloc/$regional_bloc|);
}

sub _request {
    my ($self, $endpoint, $queries) = @_;

    return if (!defined $endpoint || length $endpoint <= 0);

    $queries ||= {};

    # ?fields=name;capital;currencies
    if (scalar @{$self->fields}) {
        $queries->{fields} = join(';', @{$self->fields});
    }

    # In case the api_url was updated.
    $self->server($self->api_url);
    $self->type(qq|application/json|);

    my $path = $endpoint;

    my $response = $self->get($path, $queries);

    return $response->data;
}


1;
__END__

=encoding utf-8

=head1 NAME

WebService::RESTCountries - A Perl module to interface with the REST Countries
(restcountries.eu) webservice.

=head1 SYNOPSIS

  use WebService::RESTCountries;

  my $api = WebService::RESTCountries->new;
  $api->search_all();

=head1 DESCRIPTION

WebService::RESTCountries is a Perl client helper library for the REST
Countries API (restcountries.eu).

=head1 DEVELOPMENT

Source repo at L<https://github.com/kianmeng/webservice-restcountries|https://github.com/kianmeng/webservice-restcountries>.

=head2 Docker

If you have Docker installed, you can build your Docker container for this
project.

    $ docker build -t webservice-restcountries .
    $ docker run -it -v $(pwd):/root webservice-restcountries bash
    # cpanm --installdeps --notest .

=head2 Milla

Setting up the required packages.

    $ milla authordeps --missing | cpanm
    $ milla listdeps --missing | cpanm

Check you code coverage.

    $ milla cover

Several ways to run the test.

    $ milla test
    $ milla test --author --release
    $ AUTHOR_TESTING=1 RELEASE_TESTING=1 milla test
    $ AUTHOR_TESTING=1 RELEASE_TESTING=1 milla run prove t/01_instantiation.t
    $ LOGGING=1 milla run prove t/t/02_request.t

Release the module.

    $ milla build
    $ milla release

=head1 METHODS

=head2 new([%$args])

Construct a new WebService::RESTCountries instance. Optionally takes a hash or hash reference.

    # Instantiate the class.
    my $api = WebService::RESTCountries->new;

=head3 api_url

The URL of the API resource.

    # Instantiate the class by setting the URL of the API endpoints.
    my $api = WebService::RESTCountries->new(api_url => 'https://example.com/v2/');

    # Set through method.
    $api->api_url('https://example.com/v2/');

=head3 fields

Show the country data in specified fields. Do this before making any webservice
calls.

    # Instantiate the class by setting the selected fields.
    my $api = WebService::RESTCountries->new(fields => ['capital', 'currencies', 'name']);

    # Set through method.
    $api->fields(['capital', 'currencies', 'name']);
    my $counties = $api->search_all();

=head2 ping()

Check whether the API endpoint is currently up.

    # Returns 1 if up and 0 otherwise.
    $api->ping();

=head2 search_all()

Get all the countries.

=head2 search_by_calling_code($calling_code)

Get the details of a country by its calling code, the prefixes for the country
phone numbers.

    $api->search_by_calling_code('60');

=head2 search_by_capital_city($capital_city)

Get the details of a country by its capital city.

    # Full name.
    $api->search_by_capital_city("Kuala Lumpur");

    # Partial name.
    $api->search_by_capital_city("Kuala");

=head2 search_by_country_code($country_code)

Get the details of a country by its ISO 3166 two-letters or three-letters
country code.

    # Two-letters.
    $api->search_by_country_code("MY");

    # Three-letters.
    $api->search_by_country_code("MYS");

=head2 search_by_country_codes($country_codes)

Get the list of country by multiple ISO 3166 two-letters or three-letters
country codes.

    # Two-letters.
    $api->search_by_country_codes(['MY', 'SG']);

    # Three-letters.
    $api->search_by_country_codes(['MYS', 'SGP']);

=head2 search_by_country_full_name($full_name)

Get the details of a country by its full name.

    $api->search_by_country_full_name("São Tomé and Príncipe");

=head2 search_by_country_name($name)

Get the details of a country by name, either by native or partial name.

    # Native name.
    $api->search_by_country_name("Malaysia");

    # Partial name.
    $api->search_by_country_name("Malays");

=head2 search_by_currency($currency)

Get the details of a country by ISO 4217 currency code.

    $api->search_by_currency("MYR");

=head2 search_by_language_code($language_code)

Get the details of the a country by ISO 639-1 language code.

    $api->search_by_language_code("ms");

=head2 search_by_region($region)

Get list of country by region: Africa, Americas, Asia, Europe, Oceania. Region
name is case insensitive.

    $api->search_by_region("Asia");
    $api->search_by_region("asia");

=head2 search_by_regional_bloc($regional_bloc)

Get list of country by regional bloc: EU, EFTA, CARICOM, PA, AU, USAN, EEU, AL,
ASEAN, CAIS, CEFTA, NAFTA, SAARC. Regional bloc name is case insensitive.

    $api->search_by_region_bloc("EU");
    $api->search_by_regional_bloc("asean");

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Kian Meng, Ang.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

=head1 AUTHOR

Kian Meng, Ang E<lt>kianmeng@users.noreply.github.comE<gt>

=cut
