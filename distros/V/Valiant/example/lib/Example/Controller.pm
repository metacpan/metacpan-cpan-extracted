package Example::Controller;

use Moose;
extends 'Catalyst::ControllerPerContext';

around gather_default_action_roles => sub {
  my ($orig, $self, %args) = @_;
  my @roles = $self->$orig(%args);
  push @roles, 'Catalyst::ActionRole::ReceiveArgs';
  push @roles, 'Catalyst::ActionRole::CurrentView'
    if $args{attributes}->{View};
  push @roles, 'Catalyst::ActionRole::RequestModel'
    if $args{attributes}->{RequestModel};
  push @roles, 'Catalyst::ActionRole::Verbs'
    if $args{attributes}->{Verbs} || $args{attributes}->{Allow};

  return @roles;
};

__PACKAGE__->meta->make_immutable;
