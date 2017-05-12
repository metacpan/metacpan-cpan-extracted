package MyApp::Controller;

use Moose;
use MooseX::NonMoose;
extends 'WebNano::Controller';

sub search_subcontrollers { 1 }

sub index_action {
    my $self = shift;
    my $res = $self->req->new_response();
    $res->redirect( '/DvdWithBaseCRUD' );
    return $res;
}



1;

