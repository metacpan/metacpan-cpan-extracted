package CattySession;

use strict;

#use Catalyst;
use Catalyst qw/
    Session
    Session::State::Cookie
    Session::Store::Dummy
    /;
use Cwd;
use MIME::Base64;

our $VERSION = '0.01';

CattySession->config(
    name => 'CattySession',
    root => cwd . '/t/root',
);

CattySession->setup();

sub auto : Private {
    my ( $self, $context ) = @_;
    if ( $context->session ) {
        return 1;
    }

}

sub default : Private {
    my ( $self, $context ) = @_;
    my $html = html( "Root", "This is the root page" );
    $context->response->content_type("text/html");
    $context->response->output($html);
}

sub name : Global {
    my ($self, $c) = @_;

    my $html = html( $c->config->{name}, "This is the die page" );
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

1;

