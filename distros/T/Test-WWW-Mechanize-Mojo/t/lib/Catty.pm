package Catty;

use strict;
use warnings;

#use Catalyst;
use Catalyst;
use Cwd;
use MIME::Base64;
use Encode qw//;

our $VERSION = '0.01';

Catty->config(
    name => 'Catty',
    root => cwd . '/t/root',
);
Catty->setup();
Catty->log->levels("fatal");

sub default : Private {
    my ( $self, $context ) = @_;
    my $html = html( "Root", "This is the root page" );
    $context->response->content_type("text/html");
    $context->response->output($html);
}

sub hello : Global {
    my ( $self, $context ) = @_;
    my $str = Encode::encode('utf-8', "\x{263A}"); # ☺
    my $html = html( "Hello", "Hi there! $str" );
    $context->response->content_type("text/html; charset=utf-8");
    $context->response->output($html);
}

# absolute redirect
sub hi : Global {
    my ( $self, $context ) = @_;
    my $where = $context->uri_for('hello');
    $context->response->redirect($where);
    return;
}

# partial (relative) redirect
sub greetings : Global {
    my ( $self, $context ) = @_;
    $context->response->redirect("hello");
    return;
}

# redirect to a redirect
sub bonjour : Global {
    my ( $self, $context ) = @_;
    my $where = $context->uri_for('hi');
    $context->response->redirect($where);
    return;
}

sub check_auth_basic : Global {
    my ( $self, $context ) = @_;

    my $auth = $context->req->headers->authorization;
    ($auth) = $auth =~ /Basic\s(.*)/i;
    $auth = decode_base64($auth);

    if ( $auth eq "user:pass" ) {
        my $html = html( "Auth", "This is the auth page" );
        $context->response->content_type("text/html");
        $context->response->output($html);
        return $context;
    } else {
        my $html = html( "Auth", "Auth Failed!" );
        $context->response->content_type("text/html");
        $context->response->output($html);
        $context->response->status("401");
        return $context;
    }
}

sub redirect_with_500 : Global {
    my ( $self, $c ) = @_;
    $DB::single = 1;
    $c->res->redirect( $c->uri_for("/bonjour"));
    die "erk!";
}

sub die : Global {
    my ( $self, $context ) = @_;
    my $html = html( "Die", "This is the die page" );
    $context->response->content_type("text/html");
    $context->response->output($html);
    die "erk!";
}

sub name : Global {
    my ($self, $c) = @_;

    my $html = html( $c->config->{name}, "This is the die page" );
    $c->response->content_type("text/html");
    $c->response->output($html);
}

sub host : Global {
    my ($self, $c) = @_;

    my $host = $c->req->header('Host') || "<undef>";
    my $html = html( $c->config->{name}, "Host: $host" );
    $c->response->content_type("text/html");
    $c->response->output($html);
}

sub html {
    my ( $title, $body ) = @_;
    return qq{
<html>
<head><title>$title</title></head>
<body>
$body
<a href="/hello/">Hello</a>.
</body></html>
};
}

sub gzipped : Global {
    my ( $self, $c ) = @_;

  # If done properly this test should check the accept-encoding header, but we
  # control both ends, so just always gzip the response.
    require Compress::Zlib;

    my $html = html( "Hello", "Hi there! ☺" );
    $c->response->content_type("text/html; charset=utf-8");
    $c->response->output( Compress::Zlib::memGzip($html) );
    $c->response->content_encoding('gzip');
    $c->response->headers->push_header( 'Vary', 'Accept-Encoding' );
}

sub user_agent : Global {
    my ( $self, $c ) = @_;

    my $html = html($c->req->user_agent, $c->req->user_agent);
    $c->response->content_type("text/html; charset=utf-8");
    $c->response->output( $html );

}

1;

