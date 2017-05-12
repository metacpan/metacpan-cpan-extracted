package WebApp;
# Simple web app example using Plack. To run it:
# plackup examples/oauth_web.psgi

use 5.14.1;
use Moo;
use Encode qw/encode_utf8/;
use HTML::Escape qw/escape_html/;
use Plack::Request;
use Plack::Response;
use Twitter::API;

has twitter_client => (
    is => 'ro',
    default => sub {
        Twitter::API->new_with_traits(
            traits => 'Enchilada',
            # Net::Twitter example app credentials:
             map(tr/A-Za-z/N-ZA-Mn-za-m/r, qw/
                 pbafhzre_xrl i8g3WVYxFglyotakTYBD
                 pbafhzre_frperg 5e31eFZp0ACgOcUpX8ZiaPYt2bNlSYk5rTBZxKZ
            /),
            # To use your own app credentials:
            # consumer_key    => 'your-app-key',
            # consumer_secret => 'your-app-secret',
        );
    },
);

# In a production application, use something like Redis to store request token
# secrets. Twitter expires request tokens after 15 minutes. Your app should
# keep them just a bit longer to ensure you don't discard them before Twitter
# does. Maybe 20 minutes. In this simple demo, we won't worry about expiration.
has secret_cache => (
    is => 'ro',
    default => sub { {} },
);

# We only need it once, so remove it from the cache
sub get_secret { delete $_[0]->secret_cache->{$_[1]} }
sub set_secret { $_[0]->secret_cache->{$_[1]} = $_[2] }

sub uri_for {
    my ( $self, $req, $path ) = @_;

    my $uri = $req->base;
    $uri->path($uri->path . $path);
    return $uri;
}

my %route = (
    '/'               => 'home_page',
    '/oauth_callback' => 'oauth_callback',
);

sub dispatch {
    my ( $self, $req, $res ) = @_;

    my $method = $route{$req->path} // 'not_found';
    $self->$method($req, $res);
}

sub handle_request {
    my ( $self, $env ) = @_;

    my $req = Plack::Request->new($env);
    my $res = Plack::Response->new(200);
    $res->content_type('text/html; charset=utf-8');

    $self->dispatch($req, $res);
    $res->finalize;
}

sub to_app {
    my $self = shift->new;
    sub { $self->handle_request(@_) };
};

sub home_page {
    my ( $self, $req, $res ) = @_;

    my $client = $self->twitter_client;

    # If we have access token/secret, display verify_credentials response
    if ( my $credentials = $req->cookies->{'dont-do-this-at-home'} ) {
        my ( $token, $secret ) = split /\s+/, $credentials;
        my $r = $client->verify_credentials({
            -token        => $token,
            -token_secret => $secret,
        });
        my $body = escape_html(
            $client->json_parser->pretty(1)->encode($r)
        );
        $res->body("<pre>$body</pre>");
    }
    else {
        # Otherwise, prompt the user to authenticate
        my $r = $client->oauth_request_token({
            callback => $self->uri_for($req, 'oauth_callback'),
        });
        my ( $token, $secret ) = @{$r}{qw/oauth_token oauth_token_secret/};

        # Save the request token and secret; we'll need them later.
        $self->set_secret($token, $secret);

        my $url = $client->oauth_authentication_url({
            oauth_token => $token,
        });
        $res->body(qq{<a href="$url">Authenticate with Twitter</a>});
    }
}

sub oauth_callback {
    my ( $self, $req, $res ) = @_;

    my $token    = $req->param('oauth_token');
    my $verifier = $req->param('oauth_verifier');

    if ( $token && $verifier ) {
        # The user authenticated!

        # Get our cached request token secret
        my $secret = $self->get_secret($token) // die 'missing secret';
        my $r = $self->twitter_client->oauth_access_token({
            token        => $token,
            token_secret => $secret,
            verifier     => $verifier,
        });

        # DON'T DO THIS AT HOME!
        #
        # In a production app, you will store the access_token and
        # access_token_secret in a database. They can be used to make Twitter
        # API calls on behalf of the authenticated user. Ideally, you should
        # treat them like you would user names and passwords. Encrypt them.
        #
        # For our simple demo, since we don't have a permanent data store,
        # we'll store them in a session cookie.
        $res->cookies->{'dont-do-this-at-home'} = join ' ',
            $$r{oauth_token}, $$r{oauth_token_secret};

        $res->redirect($self->uri_for($req, ''));
        return;
    }

    my $home = $self->uri_for($req, '');
    if ( $token = $req->param('denied') ) {
        # The user canceled the authentication request and select "return to
        # the application".
        $self->get_secret($token); # discard; no longer valid or useful
        $res->body(qq{You denied us access. <a href="$home">Go home</a>});
        return;
    }

    # /oauth_callback was requested without the expected parameters; let's just
    # redirect to the root page
    $res->redirect($home);
}

sub not_found {
    my ( $self, $req, $res ) = @_;

    my $home = $self->uri_for($req, '');
    $res->status(404);
    $res->body($req->path_info
        . qq{ does not live here, try <a href="$home">the main page</a>});
}

my $app = __PACKAGE__->to_app;
