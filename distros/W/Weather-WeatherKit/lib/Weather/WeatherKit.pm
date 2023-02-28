package Weather::WeatherKit;

use 5.008;
use strict;
use warnings;

use Carp;
use Crypt::JWT qw(encode_jwt);

=head1 NAME

Weather::WeatherKit - Apple WeatherKit REST API client

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

    use Weather::WeatherKit;

    my $wk = Weather::WeatherKit->new(
        team_id    => $apple_team_id,          # Apple Developer Team Id
        service_id => $weatherkit_service_id,  # WeatherKit Service Id
        key_id     => $key_id,                 # WeatherKit developer key ID
        key        => $private_key             # Encrypted private key (PEM)
    );
    
    my $report = $wk->get(
        lat      => $lat,      # Latitude
        lon      => $lon,      # Longitude
        dataSets => $datasets  # e.g. currentWeather (comma-separated list)
    );

=head1 DESCRIPTION

Weather::WeatherKit provides basic access to the Apple WeatherKit REST API (v1).
WeatherKit replaces the Dark Sky API and requires an Apple developer subscription.

Pease see the L<official API documentation|https://developer.apple.com/documentation/weatherkitrestapi>
for datasets and usage options as well as the L<required attribution|https://developer.apple.com/weatherkit/get-started/#attribution-requirements>.

It was made to serve the apps L<Xasteria|https://astro.ecuadors.net/xasteria/> and
L<Polar Scope Align|https://astro.ecuadors.net/polar-scope-align/>, but if your service
requires some extra functionality, feel free to contact the author about it.

=head1 CONSTRUCTOR

=head2 C<new>

    my $wk = Weather::WeatherKit->new(
        team_id    => "MLU84X58U4",
        service_id => "com.domain.myweatherapp",
        key_id     => $key_id,
        key        => $private_key?,
        key_file   => $private_key_pem?,
        language   => $lang_code?,
        timeout    => $timeout_sec?,
        expiration => $expire_secs?,
        ua         => $lwp_ua?,
        curl       => $use_curl?
    );
  
Required parameters:

=over 4

=item * C<team_id> : Your 10-character Apple developer Team Id - it can be located
on the Apple developer portal.

=item * C<service_id> : The WeatherKit Service Identifier created on the Apple
developer portal. Usually a reverse-domain type string is used for this.

=item * C<key_id> : The ID of the WeatherKit key created on the Apple developer portal.

=item * C<key_file> : The encrypted WeatherKit private key file that you created on
the Apple developer portal. On the portal you download a PKCS8 format file (.p8),
which you first need to convert to the PEM format. On a Mac you can convert it simply:

   openssl pkcs8 -nocrypt -in AuthKey_<key_id>.p8 -out AuthKey_<key_id>.pem

=item * C<key> : Instead of the C<.pem> file, you can pass its contents directly
as a string.

=back

Optional parameters:

=over 4

=item * C<language> : Language code. Default: C<en_US>.

=item * C<timeout> : Timeout for requests in secs. Default: C<30>.

=item * C<ua> : Pass your own L<LWP::UserAgent> to customise the agent string etc.

=item * C<curl> : If true, fall back to using the C<curl> command line program.
This is useful if you have issues adding http support to L<LWP::UserAgent>, which
is the default method for the WeatherKit requests.

=item * C<expiration> : Token expiration time in seconds. Tokens are cached until
there are less than 10 minutes left to expiration. Default: C<7200>.

=back

=head1 METHODS

=head2 C<get>

    my $report = $wk->get(
        lat      => $lat,
        lon      => $lon,
        dataSets => $datasets
        %args?
    );

    my %report = $wk->get( ... );

Fetches datasets (weather report, forecast, alert...) for the requested location.
Returns a string containing the JSON data, except in array context, in which case,
as a convenience, it will use L<JSON> to decode it directly to a Perl hash.

Requires L<LWP::UserAgent>, unless the C<curl> option was set.

If the request is not successful, it will C<die> throwing the C<< HTTP::Response->status_line >>.

=over 4
 
=item * C<lat> : Latitude (-90 to 90).

=item * C<lon> : Longitude (-18 to 180).

=item * C<dataSets> : A comma-separated string of the dataset(s) you request. Example
supported data sets: C<currentWeather, forecastDaily, forecastHourly, forecastNextHour, weatherAlerts>.
Some data sets might not be available for all locations. Will return empty results
if parameter is missing.

=item * C<%args> : See the official API documentation for the supported weather API
query parameters which you can pass as key/value pairs.

=back

=head2 C<get_response>

    my $response = $wk->get_response(
        lat      => $lat,
        lon      => $lon,
        dataSets => $datasets
        %args?
    );

Same as C<get> except it returns the full L<HTTP::Response> from the API (so you
can handle bad requests yourself).

=head1 CONVENIENCE METHODS

=head2 C<jwt>

    my $jwt = $wk->jwt(
        iat => $iat?,
        exp => $exp?
    );

Returns the JSON Web Token string in case you need it. Will return a cached one
if it has more than 10 minutes until expiration and you don't explicitly pass an
C<exp> argument.

=over 4
 
=item * C<iat> : Specify the token creation timestamp. Default is C<time()>.

=item * C<exp> : Specify the token expiration timestamp. Passing this parameter
will force the creation of a new token. Default is C<time()+7200> (or what you
specified in the constructor).

=back

=cut

sub new {
    my $class = shift;

    my $self = {};
    bless($self, $class);

    my %args = @_;

    croak("10 digit team_id expected.") unless $args{team_id} && length($args{team_id}) == 10;
    $self->{team_id} = $args{team_id};

    ($self->{$_} = $args{$_} || croak("$_ required."))
        foreach qw/service_id key_id/;

    unless ($args{key}) {
        croak("key or key_file required.") unless $args{key_file};
        open my $fh, '<', $args{key_file} or die "Can't open file $!";
        $args{key} = do { local $/; <$fh> };
    }
    $self->{key}        = \$args{key};
    $self->{language}   = $args{language} || "en_US";
    $self->{timeout}    = $args{timeout}  || 30;
    $self->{expiration} = $args{expiration}  || 7200;
    $self->{ua}         = $args{ua};
    $self->{curl}       = $args{curl};

    return $self;
}

sub get {
    my $self = shift;
    my %args = @_;

    my $resp = $self->get_response(%args);

    return _output($resp, wantarray) if $self->{curl};

    if ($resp->is_success) {
        return _output($resp->decoded_content, wantarray);
    }
    else {
        die $resp->status_line;
    }
}

sub get_response {
    my $self = shift;
    my %args = @_;
    $args{language} ||= $self->{language};

    croak("lat between -90 and 90 expected")
        unless defined $args{lat} && abs($args{lat}) <= 90;

    croak("lon between -180 and 180 expected")
        unless defined $args{lon} && abs($args{lon}) <= 180;

    my $url = _weather_url(%args);
    my $jwt = $self->jwt;

    unless ($self->{curl} || $self->{ua}) {
        require LWP::UserAgent;
        $self->{ua} = LWP::UserAgent->new(
            agent   => "libwww-perl Weather::WeatherKit/$VERSION",
            timeout => $self->{timeout}
        );
    }

    return _fetch($self->{ua}, $url, $jwt);
}

sub jwt {
    my $self = shift;
    my %args = @_;

    # Return cached one
    return $self->{jwt}
        if !$args{exp} && $self->{jwt_exp} && $self->{jwt_exp} >= time() + 600;

    $args{iat} ||= time();
    $self->{jwt_exp} = $args{exp} || (time() + $self->{expiration});

    my $data = {
        iss => $self->{team_id},
        sub => $self->{service_id},
        exp => $self->{jwt_exp},
        iat => $args{iat}
    };

    $self->{jwt} = encode_jwt(
        payload       => $data,
        alg           => 'ES256',
        key           => $self->{key},
        extra_headers => {
            kid => $self->{key_id},
            id  => "$self->{team_id}.$self->{service_id}",
            typ => "JWT"
        }
    );

    return $self->{jwt};
}

sub _fetch {
    my ($ua, $url, $jwt) = @_;

    return
        `curl "$url" -A "Curl Weather::WeatherKit/$VERSION" -s -H 'Authorization: Bearer $jwt'`
        unless $ua;

    return $ua->get($url, Authorization => "Bearer $jwt");
}

sub _weather_url {
    my %args = @_;
    my $url =
        "https://weatherkit.apple.com/api/v1/weather/{language}/{lat}/{lon}";

    $url =~ s/{$_}/delete $args{$_}/e foreach qw/language lat lon/;

    my $params = join("&", map {"$_=$args{$_}"} keys %args);

    $url .= "?$params" if $params;

    return $url;
}

sub _output {
    my $str  = shift;
    my $json = shift;

    return $str unless $json;

    require JSON;
    return %{JSON::decode_json($str)};
}

=head1 AUTHOR

Dimitrios Kechagias, C<< <dkechag at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests either on L<GitHub|https://github.com/dkechag/Weather-WeatherKit> (preferred), or on RT (via the email
C<bug-weather-weatherkit at rt.cpan.org> or L<web interface|https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Weather-WeatherKit>).

I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 GIT

L<https://github.com/dkechag/Weather-WeatherKit>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023 by Dimitrios Kechagias.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
