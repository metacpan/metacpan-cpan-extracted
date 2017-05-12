package CattySession::Controller::Root;

use strict;
use warnings;

use base qw/ Catalyst::Controller /;

__PACKAGE__->config( namespace => '' );

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

