package Vote::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

Vote::Controller::Root - Root Controller for Vote

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 default

=cut

sub begin : Private {
    my ( $self, $c ) = @_;
    $c->model('Vote')->db->rollback;
}

sub default : Private {
    my ( $self, $c ) = @_;

    $c->stash->{page}{title} = 'Epoll ' . $Vote::VERSION;
}

=head2 end

Attempt to render a view, if needed.

=cut 

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Thauvin Olivier

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself or CeCILL.

=cut

1;
