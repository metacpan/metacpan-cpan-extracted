package Vote::Controller::Vote;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

Vote::Controller::Vote - Catalyst Controller

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

    $c->redirect($c->uri_for('/'));
}

sub default : LocalPath {
    my ( $self, $c, undef, $id ) = @_;

    $c->stash->{voteid} = $id;
    $c->stash->{page}{title} = 'Vote: ' . $c->model('Vote')->vote_info($id)->{label};
}

=head1 AUTHOR

Thauvin Olivier

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself or CeCILL.

=cut

1;
