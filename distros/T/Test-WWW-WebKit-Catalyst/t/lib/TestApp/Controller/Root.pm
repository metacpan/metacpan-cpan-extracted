package TestApp::Controller::Root;
use common::sense;

use base qw/Catalyst::Controller/;

__PACKAGE__->config( namespace => '' );

sub index : Path {
    my ($self, $c) = @_;

    return $c->res->body('jay!');
}

sub default : Private {
    my ($self, $c) = @_;

    return $c->res->body('default!');
}

1;
