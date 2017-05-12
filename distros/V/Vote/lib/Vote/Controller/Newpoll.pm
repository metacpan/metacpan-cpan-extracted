package Vote::Controller::Newpoll;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

Vote::Controller::Newpoll - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub begin : Private {
    my ( $self, $c ) = @_;
    $c->model('Vote')->db->rollback;
}

sub index : Private {
    my ( $self, $c ) = @_;

    $c->stash->{page}{title} = 'Créer un nouveau vote';
    if ($c->req->param('mail')) {
        $c->model('Vote')->create_poll_request(
            mail => $c->req->param('mail'),
            url => $c->uri_for('/newpoll'),
            label => $c->req->param('label'),
        );
        $c->stash->{template} = 'newpoll/request.tt';
    }

}

sub default : LocalPath {
    my ( $self, $c, undef, $id ) = @_;

    $c->stash->{reqid} = $id;

    if (!$c->model('Vote')->poll_request_info($id)) {
        $c->stash->{page}{title} = "Aucune requête de création de vote";
        $c->stash->{template} = 'newpoll/norequest.tt';
        return;
    }

    $c->stash->{page}{title} = 'Confirmer la création d\'un nouveau vote';
    if ($c->req->param('passwd')) {
        my $pid = $c->model('Vote')->poll_from_request($id, $c->req->param('passwd'));
        $c->res->redirect($c->uri_for('/admin', $pid));
    }
}

=head1 AUTHOR

Thauvin Olivier

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself or CeCILL.

=cut

1;
