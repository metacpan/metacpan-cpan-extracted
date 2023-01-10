package WebService::DS::SOP::Auth::V1_1;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.05";

use Carp ();
use URI;
use WebService::DS::SOP::Auth::V1_1::Request::DELETE;
use WebService::DS::SOP::Auth::V1_1::Request::GET;
use WebService::DS::SOP::Auth::V1_1::Request::POST;
use WebService::DS::SOP::Auth::V1_1::Request::POST_JSON;
use WebService::DS::SOP::Auth::V1_1::Request::PUT;
use WebService::DS::SOP::Auth::V1_1::Request::PUT_JSON;
use WebService::DS::SOP::Auth::V1_1::Util qw(is_signature_valid);

sub new {
    my ($class, $args) = @_;
    $args ||= +{};

    do {
        Carp::croak("Missing required parameter: ${_}") if not $args->{$_};
        }
        for qw( app_id app_secret );

    $args->{time} = time if not $args->{time};

    bless $args, $class;
}

sub app_id     { $_[0]->{app_id} }
sub app_secret { $_[0]->{app_secret} }
sub time       { $_[0]->{time} }

sub create_request {
    my ($self, $type, $uri, $params) = @_;
    $uri = URI->new($uri) if not ref $uri;
    my $request_maker = "WebService::DS::SOP::Auth::V1_1::Request::${type}";
    $request_maker->create_request($uri, { %$params, app_id => $self->app_id, time => $self->time },
        $self->app_secret,);
}

sub verify_signature {
    my ($self, $sig, $params) = @_;
    eval { is_signature_valid($sig, $params, $self->app_secret, $self->time); };
}

1;
__END__

=encoding utf-8

=head1 NAME

WebService::DS::SOP::Auth::V1_1 - SOP version 1.1 authentication module

=head1 SYNOPSIS

    use WebService::DS::SOP::Auth::V1_1;

To create an instance:

    my $auth = WebService::DS::SOP::Auth::V1_1->new({
        app_id => '1',
        app_secret => 'hogehoge',
    });


When making a GET request to API:

    my $req = $auth->create_request(
        GET => 'https://<API_HOST>/path/to/endpoint' => {
            hoge => 'hoge',
            fuga => 'fuga',
        },
    );

    my $res = LWP::UserAgent->new->request($req);

When making a POST request with JSON data to API:

    my $req = $auth->create_request(
        POST_JSON => 'http://<API_HOST>/path/to/endpoint' => {
            hoge => 'hoge',
            fuga => 'fuga',
        },
    );

    my $res = LWP::UserAgent->new->request($req);

When embedding JavaScript URL in page:

    <script src="<: $req.uri.as_string :>"></script>

=head1 DESCRIPTION

WebService::DS::SOP::Auth::V1_1 is an authentication module
for L<SOP|http://console.partners.surveyon.com/> version 1.1
by L<Research Panel Asia, Inc|http://www.researchpanelasia.com/>.

=head1 METHODS

=head2 new( \%options ) returns WebService::DS::SOP::Auth::V1_1

Creates a new instance.

Possible options:

=over 4

=item C<app_id>

(Required) Your C<app_id>.

=item C<app_secret>

(Required) Your C<app_secret>.

=item C<time>

(Optional) POSIX time.

=back

=head2 app_id() returns Int

Returns C<app_id> configured to instance.

=head2 app_secret() returns Str

Returns C<app_secret> configured to instance.

=head2 time returns Int

Returns C<time> configured to instance.

=head2 create_request( Str $type, Any $uri, Hash $params ) returns HTTP::Request

Returns a new L<HTTP::Request> object for API request while adding C<app_id> to parameters by default.

I<$type> can be one of followings:

=over 4

=item C<GET>

For HTTP GET request to SOP endpoint with signature in query string as parameter
B<sig>.

=item C<POST>

For HTTP POST request to SOP endpoint with signature in query string as
parameter B<sig> of request content type C<application/x-www-form-urlencoded>.

=item C<POST_JSON>

For HTTP POST request to SOP endpoint with signature as request header
C<X-Sop-Sig> of request content type C<application/json>.

=item C<PUT>

For HTTP PUT request to SOP endpoint with signature in query string as
parameter B<sig> of request content type C<application/x-www-form-urlencoded>.

=item C<PUT_JSON>

For HTTP PUT request to SOP endpoint with signature as request header
C<X-Sop-Sig> of request content type C<application/json>.

=item C<DELETE>

For HTTP DELETE request to SOP endpoint with signature in query string as parameter
B<sig>.

=back

=head2 verify_signature( Str $sig, Hash $params ) return Int

Verifies and returns if request signature is valid.

=head1 SEE ALSO

L<WebService::DS::SOP::Auth::V1_1::Request::DELETE>,
L<WebService::DS::SOP::Auth::V1_1::Request::GET>,
L<WebService::DS::SOP::Auth::V1_1::Request::POST>,
L<WebService::DS::SOP::Auth::V1_1::Request::POST_JSON>,
L<WebService::DS::SOP::Auth::V1_1::Request::PUT>,
L<WebService::DS::SOP::Auth::V1_1::Request::PUT_JSON>,
L<WebService::DS::SOP::Auth::V1_1::Util>

=head1 LICENSE

Copyright (C) dataSpring, Inc.
Copyright (C) Research Panel Asia, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

yowcow E<lt>yoko.oyama [ at ] d8aspring.comE<gt>

=cut

