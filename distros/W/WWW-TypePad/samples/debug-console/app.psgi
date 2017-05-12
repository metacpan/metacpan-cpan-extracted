#!/usr/bin/perl

# Make debug console application on your browser
# DO NOT PUBLISH THIS APPLICATION TO THE INTERNET

use strict;
use warnings;
use Data::Dumper;
use Plack::Request;
use Plack::Builder;
use Text::MicroTemplate qw( render_mt );
use WWW::TypePad;

# These should be set to the Consumer Key and Consumer Secret
# for your TypePad application. You can obtain these values from
# http://www.typepad.com/account/access/api_key.
our $ConsumerKey = $ENV{TP_CONSUMER_KEY};
our $ConsumerSecret = $ENV{TP_CONSUMER_SECRET};

sub error {
    my( $code, $html ) = @_;
    return [
        $code,
        [ 'Content-Type', 'text/html' ],
        [ $html ],
    ];
}

sub Plack::Request::uri_for {
    my $req = shift;
    my( $path ) = @_;
    $path = '/' . $path unless $path =~ m{^/};
    return 'http://' . $req->env->{HTTP_HOST} . $path;
}

sub tp {
    my $tp = WWW::TypePad->new(
        consumer_key        => $ConsumerKey,
        consumer_secret     => $ConsumerSecret,
    );
    $tp->host($ENV{TP_API_HOST}) if $ENV{TP_API_HOST};
    $tp;
}

my $home = sub {
    my $req = Plack::Request->new( shift );
    my $tp = tp();

    # Do we have a logged-in user? If so, make an API request to pull down
    # the user's profile info. Not that we're not using the access token
    # and access token secret here, since this is a public API; but the
    # access token and secret that we stored in the session could be used
    # to make authenticated requests acting on behalf of the logged-in user.
    my $session = $req->session;
    my $obj;
    if ( $session && $session->{user} ) {
        $tp->access_token( $session->{user}{token} );
        $tp->access_token_secret( $session->{user}{token_secret} );
        $obj = $tp->users->get( $session->{user}{xid} );
    }

    local $Data::Dumper::Indent = 1;

    my $code = $req->parameters->{code};
    my($result, $err, $warn);
    if ($code && $obj) {
        # WHOAH
        my $user = $obj; # alias
        local $SIG{__WARN__} = sub { $warn .= $_[0] };
        $result = eval "no strict; $code";
        $err = $@ if $@;
    } else {
        $code = <<'CODE';
# $tp is WWW::TypePad object
# $user is User
CODE
    }

    my $html = render_mt( <<'HTML', $obj, $code, $result, $err, $warn );
? my($user, $code, $res, $err, $warn) = @_;
<html>
<head>
    <title>TypePad API debug console</title>
    <style type="text/css">
    body { font-family: Helvetica, Arial, Verdana, sans-serif; text-align: center; color: #333; }
    h3 { margin-top: 60px; font-size: 48px; }
    h5 { font-size: 12px; }
    .error { font-color: #f00 }
    .console { width: 500px }
    </style>
</head>
<body>
? if ( $user ) {
    <h3>Welcome back, <a href="http://profile.typepad.com/<?= $user->{urlId} ?>"><?= $user->{displayName} ?></a>!</h3>
    <form action="/" method="post">
      <textarea name="code" rows="8" cols="80"><?= $code ?></textarea>
      <br/><input type="submit" value=" run "/>
    </form>
?   if ( $res ) {
      <textarea rows="16" cols="80" class="dump"><?= Dumper $res ?></textarea>
?   } elsif ( $err ) {
      <textarea rows="2" cols="80"><?= $err ?></textarea>
?   }
?   if ( $warn ) {
      <textarea rows="8" cols="80"><?= $warn ?></textarea>
?   }
    <h5><a href="/logout">(Sign out)</a></h5>
? } else {
    <h3><a href="/login">Sign in</a></h3>
? }
</body>
</html>
HTML

    my $res = Plack::Response->new( 200 );
    $res->content_type( 'text/html' );
    $res->body( $html );
    return $res->finalize;
};

my $login = sub {
    my $req = Plack::Request->new( shift );
    my $tp = tp();

    # After the user authorizes our application, he/she will be sent back
    # to the callback URI ($login_cb below).
    my $cb_uri = $req->uri_for( '/login-callback' );

    # Under the hood, get_authorization_url will request a request token,
    # then construct a URI to send the user to to authorize our app.
    my $uri = $tp->oauth->get_authorization_url(
        callback => $cb_uri,
    );

    my $res = Plack::Response->new;
    $res->redirect( $uri );

    # Store the token secret in the browser cookies for when this user
    # returns from TypePad.
    $res->cookies->{oauth_token_secret} = $tp->oauth->request_token_secret;

    return $res->finalize;
};
 
my $login_cb = sub {
    my $req = Plack::Request->new( shift );
    my $tp = tp();

    # request_token is passed back to us via the query string
    # as "oauth_token"...
    my $token = $req->query_parameters->{oauth_token}
        or return error( 400, 'No oauth_token' );

    # ... and the request_token_secret is stored in the browser cookie.
    my $token_secret = $req->cookies->{oauth_token_secret}
        or return error( 400, 'No oauth_token_secret cookie' );

    my $verifier = $req->query_parameters->{oauth_verifier}
        or return error( 400, 'No oauth_verifier' );

    $tp->oauth->request_token( $token );
    $tp->oauth->request_token_secret( $token_secret );

    # Given the request token, token secret, and verifier that TypePad
    # sent us, request an access token and secret that we can use for
    # future authenticated calls on behalf of this user.
    my( $access_token, $access_token_secret ) =
        $tp->oauth->request_access_token( verifier => $verifier );
    $tp->access_token( $access_token );
    $tp->access_token_secret( $access_token_secret );

    # Now we've got an access token; make an authenticated request to figure
    # out who we are, so we can associate the OAuth tokens to a local user.
    my $obj = $tp->users->get( '@self' );
    return error( 500, 'Request for @self gave us empty result' )
        unless $obj;

    # And store the user's xid, the access token, and access token
    # secret in a session. In a real application, we'd store these
    # in an actual datastore.
    $req->session->{user} = {
        xid             => $obj->{urlId},
        token           => $access_token,
        token_secret    => $access_token_secret,
    };

    my $res = Plack::Response->new;
    $res->redirect( $req->uri_for( '/' ) );

    # Remove the request token secret cookie that we created above.
    $res->cookies->{oauth_token_secret} = {
        value   => '',
        expires => time - 24 * 60 * 60,
    };

    return $res->finalize;
};

my $logout = sub {
    my $req = Plack::Request->new( shift );

    # Kill the session.
    $req->env->{'psgix.session'} = {};

    my $res = Plack::Response->new;
    $res->redirect( $req->uri_for( '/' ) );
    return $res->finalize;
};

builder {
    # Sign session cookies using our API secret. You could use something
    # else, if you want, but it's highly recommended to sign cookies with
    # some secret.
    enable 'Session::Cookie', secret => $ConsumerSecret;

    mount '/' => $home;
    mount '/login' => $login;
    mount '/login-callback' => $login_cb;
    mount '/logout' => $logout;

    # Kill favicon requests.
    mount '/favicon.ico' => sub { return error( 404, "not found" ) };
};
