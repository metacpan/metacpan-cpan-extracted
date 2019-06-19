package WebService::MinFraud::Client;

use 5.010;
use Moo 1.004005;
use namespace::autoclean;

our $VERSION = '1.009001';

use HTTP::Headers ();
use HTTP::Request ();
use JSON::MaybeXS;
use LWP::UserAgent;
use Scalar::Util qw( blessed );
use Sub::Quote qw( quote_sub );
use Try::Tiny qw( catch try );
use Types::Standard qw( InstanceOf );
use URI ();
use WebService::MinFraud::Error::Generic;
use WebService::MinFraud::Error::HTTP;
use WebService::MinFraud::Error::WebService;
use WebService::MinFraud::Model::Factors;
use WebService::MinFraud::Model::Insights;
use WebService::MinFraud::Model::Score;
use WebService::MinFraud::Model::Chargeback;
use WebService::MinFraud::Types
    qw( JSONObject MaxMindID MaxMindLicenseKey Str URIObject UserAgentObject );
use WebService::MinFraud::Validator;

with 'WebService::MinFraud::Role::HasLocales';

has account_id => (
    is       => 'ro',
    isa      => MaxMindID,
    required => 1,
);
*user_id = \&account_id;    # for backwards-compatibility

has _base_uri => (
    is      => 'lazy',
    isa     => URIObject,
    builder => sub {
        my $self = shift;
        URI->new( $self->uri_scheme . '://' . $self->host . '/minfraud' );
    },
);
has host => (
    is      => 'ro',
    isa     => Str,
    default => q{minfraud.maxmind.com},
);
has _json => (
    is       => 'ro',
    isa      => JSONObject,
    init_arg => undef,
    default  => quote_sub(q{ JSON::MaybeXS->new->utf8 }),
);
has license_key => (
    is       => 'ro',
    isa      => MaxMindLicenseKey,
    required => 1,
);

has timeout => (
    is      => 'ro',
    isa     => Str,
    default => q{},
);

has ua => (
    is      => 'lazy',
    isa     => UserAgentObject,
    builder => sub { LWP::UserAgent->new },
);

has uri_scheme => (
    is      => 'ro',
    isa     => Str,
    default => q{https},
);

has _validator => (
    is      => 'lazy',
    isa     => InstanceOf ['WebService::MinFraud::Validator'],
    builder => sub { WebService::MinFraud::Validator->new },
    handles => { _remove_trivial_hash_values => '_delete' },
);

around BUILDARGS => sub {
    my $orig = shift;

    my $args = $orig->(@_);

    $args->{account_id} = delete $args->{user_id} if exists $args->{user_id};

    return $args;
};

sub BUILD {
    my $self = shift;

    ## no critic (RequireBlockTermination)
    my $self_version = try { 'v' . $self->VERSION() } || 'v?';

    my $ua         = $self->ua();
    my $ua_version = try { 'v' . $ua->VERSION() } || 'v?';
    ## use critic

    my $agent
        = blessed($self)
        . " $self_version" . ' ('
        . blessed($ua) . q{ }
        . $ua_version . q{ / }
        . "Perl $^V)";

    $ua->agent($agent);
}

sub factors {
    my $self = shift;

    return $self->_response_for(
        'v2.0',
        'factors',
        'WebService::MinFraud::Model::Factors', @_,
    );
}

sub insights {
    my $self = shift;

    return $self->_response_for(
        'v2.0',
        'insights',
        'WebService::MinFraud::Model::Insights', @_,
    );
}

sub score {
    my $self = shift;

    return $self->_response_for(
        'v2.0',
        'score',
        'WebService::MinFraud::Model::Score', @_,
    );
}

sub chargeback {
    my $self = shift;

    return $self->_response_for(
        undef,
        'chargeback',
        'WebService::MinFraud::Model::Chargeback', @_,
    );
}

sub _response_for {
    my ( $self, $version, $path, $model_class, $content ) = @_;

    $content = $self->_remove_trivial_hash_values($content);

    $self->_fix_booleans($content);

    my $uri           = $self->_base_uri->clone;
    my @path_segments = ( $uri->path_segments, );
    push @path_segments, $version if $version;
    push @path_segments, $path;
    $uri->path_segments(@path_segments);

    $self->_validator->validate_request( $content, $path );
    my $request = HTTP::Request->new(
        'POST', $uri,
        HTTP::Headers->new(
            Accept         => 'application/json',
            'Content-Type' => 'application/json'
        ),
        $self->_json->encode($content)
    );

    $request->authorization_basic( $self->account_id, $self->license_key );

    my $response = $self->ua->request($request);

    if ( $response->code == 200 ) {
        my $body = $self->_handle_success( $response, $uri );
        return $model_class->new( %{$body}, locales => $self->locales, );
    }
    elsif ( $response->code == 204 ) {
        return $model_class->new;
    }
    else {
        # all other error codes throw an exception
        $self->_handle_error_status( $response, $uri );
    }
}

{
    my @Booleans = (
        [ 'order',   'is_gift' ],
        [ 'order',   'has_gift_message' ],
        [ 'payment', 'was_authorized' ],
    );

    sub _fix_booleans {
        my $self    = shift;
        my $content = shift;

        return unless $content;

        for my $boolean (@Booleans) {
            my ( $object, $key ) = @{$boolean};
            if (   !exists $content->{$object}
                || !exists $content->{$object}{$key} ) {
                next;
            }

            $content->{$object}{$key}
                = $content->{$object}{$key}
                ? JSON()->true
                : JSON()->false;
        }
    }
}

sub _handle_success {
    my $self     = shift;
    my $response = shift;
    my $uri      = shift;

    my $body;
    try {
        $body = $self->_json->decode( $response->decoded_content );
    }
    catch {
        WebService::MinFraud::Error::Generic->throw(
            message =>
                "Received a 200 response for $uri but could not decode the response as JSON: $_",
        );
    };

    return $body;
}

sub _handle_error_status {
    my $self     = shift;
    my $response = shift;
    my $uri      = shift;

    my $status = $response->code;

    if ( $status =~ /^4/ ) {
        $self->_handle_4xx_status( $response, $status, $uri );
    }
    elsif ( $status =~ /^5/ ) {
        $self->_handle_5xx_status( $status, $uri );
    }
    else {
        $self->_handle_non_200_status( $status, $uri );
    }
}

sub _handle_4xx_status {
    my $self     = shift;
    my $response = shift;
    my $status   = shift;
    my $uri      = shift;

    my $content = $response->decoded_content;

    my $has_body = defined $content && length $content;
    my $body     = try {
        $has_body
            && $response->content_type =~ /json/
            && $self->_json->decode($content)
    };

    if ($body) {
        if ( $body->{code} || $body->{error} ) {
            WebService::MinFraud::Error::WebService->throw(
                message => delete $body->{error},
                %{$body},
                http_status => $status,
                uri         => $uri,
            );
        }
        else {
            WebService::MinFraud::Error::Generic->throw( message =>
                    'Response contains JSON but it does not specify code or error keys'
            );
        }
    }
    else {
        WebService::MinFraud::Error::HTTP->throw(
            message => $has_body
            ? "Received a $status error for $uri with the following body: $content"
            : "Received a $status error for $uri with no body",
            http_status => $status,
            uri         => $uri,
        );
    }
}

sub _handle_5xx_status {
    my $self   = shift;
    my $status = shift;
    my $uri    = shift;

    WebService::MinFraud::Error::HTTP->throw(
        message     => "Received a server error ($status) for $uri",
        http_status => $status,
        uri         => $uri,
    );
}

sub _handle_non_200_status {
    my $self   = shift;
    my $status = shift;
    my $uri    = shift;

    WebService::MinFraud::Error::HTTP->throw(
        message =>
            "Received an unexpected HTTP status ($status) for $uri that is neither 2xx, 4xx nor 5xx",
        http_status => $status,
        uri         => $uri,
    );
}

1;

# ABSTRACT: Perl API for MaxMind's minFraud Score and Insights web services

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Client - Perl API for MaxMind's minFraud Score and Insights web services

=head1 VERSION

version 1.009001

=head1 SYNOPSIS

  use 5.010;

  use WebService::MinFraud::Client;

  # The Client object can be re-used across several requests.
  # Your MaxMind account_id and license_key are available at
  # https://www.maxmind.com/en/my_license_key
  my $client = WebService::MinFraud::Client->new(
      account_id  => 42,
      license_key => 'abcdef123456',
  );

  # Request HashRef must contain a 'device' key, with a value that is a
  # HashRef containing an 'ip_address' key with a valid IPv4 or IPv6 address.
  # All other keys/values are optional; see other modules in minFraud Perl API
  # distribution for details.

  my $request = { device => { ip_address => '24.24.24.24' } };

  # Use the 'score', 'insights', or 'factors' client methods, depending on
  # the minFraud web service you are using.

  my $score = $client->score( $request );
  say $score->risk_score;

  my $insights = $client->insights( $request );
  say $insights->shipping_address->is_high_risk;

  my $factors = $client->factors( $request );
  say $factors->subscores->ip_tenure;


  # Request HashRef must contain an 'ip_address' key containing  a valid
  # IPv4 or IPv6 address. All other keys/values are optional; see other modules
  # in minFraud Perl API distribution for details.

  $request = { ip_address => '24.24.24.24' };

  # Use the chargeback client method to submit an IP address back to Maxmind.
  # The chargeback api does not return any content from the server.

  my $chargeback = $client->chargeback( $request );
  if ($chargeback->isa('WebService::MinFraud::Model::Chargeback')) {
    say 'Successfully submitted chargeback';
  }

=head1 DESCRIPTION

This class provides a client API for the MaxMind minFraud Score, Insights
Factors web services, and the Chargeback web service. The B<Insights>
service returns more data about a transaction than the B<Score> service.
See the L<API documentation|https://dev.maxmind.com/minfraud/>
for more details.

Each web service is represented by a different model class, and
these model classes in turn contain multiple Record classes. The Record
classes have attributes which contain data about the transaction or IP address.

If the web service does not return a particular piece of data for a
transaction or IP address, the associated attribute is not populated.

The web service may not return any information for an entire record, in which
case all of the attributes for that record class will be empty.

=head1 TRANSPORT SECURITY

Requests to the minFraud web service are made over an HTTPS connection.

=head1 USAGE

The basic API for this class is the same for all of the web services. First you
create a web service object with your MaxMind C<account_id> and C<license_key>,
then you call the method corresponding to the specific web service, passing it
the transaction you want analyzed.

If the request succeeds, the method call will return a model class for the web
service you called. This model in turn contains multiple record classes, each of
which represents part of the data returned by the web service.

If the request fails, the client class throws an exception.

=head1 CONSTRUCTOR

This class has a single constructor method:

=head2 WebService::MinFraud::Client->new

This method creates a new client object. It accepts the following arguments:

=over 4

=item * account_id

Your MaxMind User ID. Go to L<https://www.maxmind.com/en/my_license_key> to see
your MaxMind User ID and license key.

This argument is required.

=item * license_key

Your MaxMind license key.

This argument is required.

=item * locales

This is an array reference where each value is a string indicating a locale.
This argument will be passed on to record classes to use when their C<name>
methods are called.

The order of the locales is significant. When a record class has multiple
names (country, city, etc.), its C<name> method will look at each element of
this array reference and return the first locale for which it has a name.

Note that the only locale which is always present in the minFraud data is
C<en>. If you do not include this locale, the C<name> method may return
C<undef> even when the record in question has an English name.

Currently, the valid list of locale codes is:

=over 8

=item * de - German

=item * en - English

English names may still include accented characters if that is the accepted
spelling in English. In other words, English does not mean ASCII.

=item * es - Spanish

=item * fr - French

=item * ja - Japanese

=item * pt-BR - Brazilian Portuguese

=item * ru - Russian

=item * zh-CN - Simplified Chinese

=back

Passing any other locale code will result in an error.

The default value for this argument is C<['en']>.

=item * host

The hostname of the minFraud web service used when making requests. This
defaults to C<minfraud.maxmind.com>. In most cases, you do not need to set this
explicitly.

=item * ua

This argument allows you to set your own L<LWP::UserAgent> object. This is
useful if you have to override the default object (C<< LWP::UserAgent->new() >>)
to set http proxy parameters, for example.

This attribute can be any object which supports C<agent> and C<request>
methods:

=over 8

=item * request

The C<request> method will be called with an L<HTTP::Request> object as its only
argument. This method must return an L<HTTP::Response> object.

=item * agent

The C<agent> method will be called with a User-Agent string, constructed as
described below.

=back

=back

=head1 REQUEST

The request methods are passed a HashRef as the only argument. See the L</SYNOPSIS> and L<WebService::MinFraud::Example> for detailed usage examples. Some important notes regarding values passed to the minFraud web service via the Perl API are described below.

=head2 device => ip_address or ip_address

This must be a valid IPv4 or IPv6 address in presentation format, i.e.,
dotted-quad notation or the IPv6 hexadecimal-colon notation.

=head1 REQUEST METHODS

All of the fraud service request methods require a device ip_address. See the
L<API documentation for fraud services|https://dev.maxmind.com/minfraud/>
for details on all the values that can be part of the request. Portions of the
request hash with undefined and empty string values are automatically removed
from the request.

The chargeback request method requires an ip_address. See the
L<API documentation for chargeback|https:://dev.maxmind.com/minfraud/chargeback/>
for details on all the values that can be part of the request.

=head2 score

This method calls the minFraud Score web service. It returns a
L<WebService::MinFraud::Model::Score> object.

=head2 insights

This method calls the minFraud Insights web service. It returns a
L<WebService::MinFraud::Model::Insights> object.

=head2 factors

This method calls the minFraud Factors web service. It returns a
L<WebService::MinFraud::Model::Factors> object.

=head2 chargeback

This method calls the minFraud Chargeback web service. It returns a
L<WebService::MinFraud::Model::Chargeback> object.

=head1 User-Agent HEADER

Requests by the minFraud Perl API will have a User-Agent header containing the
package name and version of this module (or a subclass if you use one), the
package name and version of the user agent object, and the version of Perl.

This header is set in order to help us support individual users, as well to determine
support policies for dependencies and Perl itself.

=head1 EXCEPTIONS

For details on the possible errors returned by the web service itself, please
refer to the
L<API documentation|https://dev.maxmind.com/minfraud/>.

Prior to making the request to the web service, the request HashRef is passed
to L<WebService::MinFraud::Validator> for checks. If the request fails
validation an exception is thrown, containing a string describing all of the
validation errors.

If the web service returns an explicit error document, this is thrown as a
L<WebService::MinFraud::Error::WebService> exception object. If some other
sort of error occurs, this is thrown as a L<WebService::MinFraud::Error::HTTP>
object. The difference is that the web service error includes an error message
and error code delivered by the web service. The latter is thrown when an
unanticipated error occurs, such as the web service returning a 500 status or an
invalid error document.

If the web service returns any status code besides 200, 4xx, or 5xx, this also
becomes a L<WebService::MinFraud::Error::HTTP> object.

Finally, if the web service returns a 200 but the body is invalid, the client
throws a L<WebService::MinFraud::Error::Generic> object.

All of these error classes have a C<< message >> method and
overload stringification to show that message. This means that if you don't
explicitly catch errors they will ultimately be sent to C<STDERR> with some
sort of (hopefully) useful error message.

=head1 WHAT DATA IS RETURNED?

Please see the
L<API documentation|https://dev.maxmind.com/minfraud/>
for details on what data each web service may return.

Every record class attribute has a corresponding predicate method so that you
can check to see if the attribute is set.

  my $insights = $client->insights( $request );
  my $issuer   = $insights->issuer;
  # phone_number attribute, with has_phone_number predicate method
  if ( $issuer->has_phone_number ) {
      say "issuer phone number: " . $issuer->phone_number;
  }
  else {
      say "no phone number found for issuer";
  }

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/minfraud-api-perl/issues>.

=head1 AUTHOR

Mateu Hunter <mhunter@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2019 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
