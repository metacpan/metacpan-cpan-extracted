package Example::Controller;

use Moose;
extends 'Catalyst::ControllerPerContext';

around gather_default_action_roles => sub {
  my ($orig, $self, %args) = @_;
  my @roles = $self->$orig(%args);
  push @roles, 'Catalyst::ActionRole::CurrentView'
    if $args{attributes}->{View};
  push @roles, 'Catalyst::ActionRole::RequestModel'
    if $args{attributes}->{RequestModel};

  return @roles;
};

__PACKAGE__->meta->make_immutable;
