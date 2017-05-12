package WWW::Desk::Auth::oAuth;

use 5.006;
use strict;
use warnings;

use Moose;
use Mojo::Path;
use Mojo::URL;
use Net::OAuth::Client;
use Tie::Hash::LRU;

=head1 NAME

WWW::Desk::Auth::oAuth - Desk.com oAuth Authentication

=cut

our $VERSION = '0.10';    ## VERSION

our %session;
our $lru = tie %session, 'Tie::Hash::LRU', 100;

=head1 ATTRIBUTES

=head2 api_key

REQUIRED - desk.com api key

=cut

has 'api_key' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

=head2 secret_key

REQUIRED - desk.com api secret key

=cut

has 'secret_key' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

=head2 desk_url

REQUIRED - your desk url

=cut

has 'desk_url' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head2 callback_url

REQUIRED - desk.com oauth callback URI

It must be a URI object

=cut

has 'callback_url' => (
    is       => 'ro',
    isa      => 'URI',
    required => 1,
);

=head2 debug

debug oAuth Requests - boolean type

=cut

has 'debug' => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        return 0;
    });

=head2 api_version

desk.com api version

=cut

has 'api_version' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        return "v2";
    });

=head2 auth_client

Net::OAuth::Client OAuth protocol object wrapper

=cut

has 'auth_client' => (
    is         => 'ro',
    isa        => 'Net::OAuth::Client',
    lazy_build => 1
);

sub _build_auth_client {
    my ($self) = @_;
    return Net::OAuth::Client->new(
        $self->api_key,
        $self->secret_key,
        protocol_version   => '1.0a',
        site               => $self->desk_url,
        authorize_path     => '/oauth/authorize',
        request_token_path => '/oauth/request_token',
        access_token_path  => '/oauth/access_token',
        callback           => $self->callback_url,
        session            => \&_session,
        debug              => $self->debug
    );
}

sub _session {
    my (@data) = @_;
    if ($data[0] && $data[1]) {
        %session = ($data[0] => $data[1]);
        return %session;
    }
    return $session{$data[0]};
}

=head1 SYNOPSIS

    use WWW::Desk::Auth::oAuth;

    my $auth = WWW::Desk::Auth::oAuth->new(
        'api_key'      => 'api key',
        'secret_key'   => 'secret key',
        'desk_url'     => 'https://my.desk.com',
        'callback_url' => 'https://myapp.com/callback'
    );

    # Visit authorization_url, approve it
    $auth->authorization_url;

    my $params; # get params from cgi
    # Use the auth code to fetch the access token
    my $access_token =  $auth->request_access_token($params->{oauth_token}, $params->{oauth_verifier});

    # Use the access token to fetch a protected resource
    my $response = $access_token->get( $auth->build_api_url('/customers') );

NOTE: Checkout demo/oAuth_demo.pl for oauth demo application


=head1 SUBROUTINES/METHODS

=head2 authorization_url

Authorization url the user needs to visit to authorize

=cut

sub authorization_url {
    my ($self) = @_;
    return $self->auth_client->authorize_url;
}

=head2 request_access_token

Request the access token and access token secret for this user.

The user must have authorized this app at the url given by authorization_url first.

Returns the access token and access token secret but also sets them internally so that after calling this method you can immediately call a restricted method.

It accept two parameters $oauth_token, $oauth_verifier.

=cut

sub request_access_token {
    my ($self, $oauth_token, $oauth_verifier) = @_;
    $self->{'oauth_token'}    = $oauth_token;
    $self->{'oauth_verifier'} = $oauth_verifier;
    return $self->auth_client->get_access_token($oauth_token, $oauth_verifier);
}

=head2 build_api_url

It build the api abosulte url with the path your supplied

Takes path as input format

=cut

sub build_api_url {
    my ($self, $path) = @_;
    my $api_version = $self->api_version;
    my $new_path    = Mojo::Path->new($path);
    $path = $new_path->leading_slash(0);
    my $url = Mojo::URL->new($self->desk_url)->path("/api/$api_version/$path")->to_abs();
    return $url;
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
