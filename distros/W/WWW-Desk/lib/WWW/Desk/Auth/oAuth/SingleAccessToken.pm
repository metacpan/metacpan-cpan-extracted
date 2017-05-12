package WWW::Desk::Auth::oAuth::SingleAccessToken;

use 5.006;
use strict;
use warnings;

use Moose;

use Net::OAuth 0.20;
use Data::Random qw(:all);
use HTTP::Request::Common;

use WWW::Desk::Browser;

our $VERSION = '0.10';    ## VERSION

extends 'WWW::Desk::Auth::oAuth';

$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;

=head1 NAME

WWW::Desk::Auth::oAuth::SingleAccessToken - Desk.com SingleAccessToken Authentication

=head1 SYNOPSIS

    use WWW::Desk::Auth::oAuth::SingleAccessToken;

    my $desk = WWW::Desk::Auth::oAuth::SingleAccessToken->new(
        desk_url       => 'https://your.desk.com/',
        api_key        => 'customer api key',
        secret_key     => 'customer secret key',
        token          => 'access token',
        token_secret   => 'access token secret'
    );

    my $tx = $desk->call('/customers/search', 'GET', {email => 'a@a.com'});

=cut

=head1 ATTRIBUTES

=head2 api_key

REQUIRED - desk.com api key

=head2 secret_key

REQUIRED - desk.com api secret key

=head2 desk_url

REQUIRED - your desk url

=head2 token

REQUIRED - desk.com access token

=cut

has 'token' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

=head2 token_secret

REQUIRED - desk.com access secret

=cut

has 'token_secret' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'browser_client' => (
    is         => 'ro',
    isa        => 'WWW::Desk::Browser',
    lazy_build => 1,
);

sub _build_browser_client {
    my ($self) = @_;
    return WWW::Desk::Browser->new(base_url => $self->desk_url);
}

has 'callback_url' => (
    is         => 'ro',
    isa        => 'URI',
    lazy_build => 1
);

sub _build_callback_url {
    my ($self) = @_;
    return URI->new;
}

=head2 call

call the api requests

REQUIRED $url_fragment, api fragment url
REQUIRED $http_method, api allowed HTTP method
OPTIONAL $params parameters to be sent

RETURNS:
    {
        'code'    => $code,
        'message' => $msg,
        'data'    => $data
    };

=cut

sub call {
    my ($self, $url_fragment, $http_method, $params) = @_;

    if (not defined $params) {
        $params = {'t' => time()};
    }

    return $self->_prepare_response("400", "Invalid HTTP method. Only supported GET, POST, PATCH, DELETE")
        unless $http_method =~ /^GET$|^POST$|^PATCH$|^DELETE$/i;

    $http_method = lc $http_method;

    my $browser_client = $self->browser_client;

    my $request_url = $self->build_api_url($url_fragment);

    my $request = Net::OAuth->request('protected resource')->new(
        consumer_key     => $self->api_key,
        consumer_secret  => $self->secret_key,
        request_url      => $request_url,
        request_method   => uc $http_method,
        signature_method => 'HMAC-SHA1',
        timestamp        => time,
        nonce            => join(
            '',
            rand_chars(
                size => 16,
                set  => 'alphanumeric'
            )
        ),
        version      => '1.0',
        token        => $self->token,
        token_secret => $self->token_secret,
    );

    $request->sign;

    my $json_params  = $params ? $browser_client->js_encode($params) : $params;
    my $http_headers = {};
    my $response     = $browser_client->browser->$http_method($request->to_url => $http_headers => $json_params);

    my $response_code    = $response->res->code;
    my $response_content = $response->res->body;
    my $error            = $response->error;

    return $self->_prepare_response($response_code || 408, $error->{'message'})
        if $error;

    return $self->_prepare_response($response_code || 200, 'OK', $response_content);
}

sub _prepare_response {
    my ($self, $code, $msg, $data) = @_;
    $data = $self->browser_client->js_decode($data) if $data;
    return {
        'code'    => $code,
        'message' => $msg,
        'data'    => $data
    };
}

=head1 AUTHOR

binary.com, C<< <rakesh at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-desk at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Desk>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Desk


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Desk>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Desk>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Desk>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Desk/>

=back


=head1 ACKNOWLEDGEMENTS

=cut

no Moose;
__PACKAGE__->meta->make_immutable();

1;    # End of WWW::Desk::Auth::oAuth
