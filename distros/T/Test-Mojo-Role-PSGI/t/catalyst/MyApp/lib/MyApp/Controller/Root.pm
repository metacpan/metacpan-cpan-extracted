package MyApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    if ($c->request->method eq 'GET') {
        # Hello World
        $c->response->body( $c->welcome_message );
    } elsif ($c->request->method eq 'POST') {
         $c->response->headers->header('Content-Type' => $c->request->headers->header('Content-Type'));
         $c->response->body($c->request->body);
    }
}

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

sub end : ActionClass('RenderView') {}

__PACKAGE__->meta->make_immutable;

1;
