package Example::Controller;

use Moose;

extends 'Catalyst::ControllerPerContext';
with 'Catalyst::ControllerRole::At',
  'Catalyst::ControllerRole::View',
  'Catalyst::ControllerRole::URI';

around gather_default_action_roles => sub {
  my ($orig, $self, %args) = @_;
  my @roles = $self->$orig(%args);
  push @roles, 'Catalyst::ActionRole::RequestModel'
    if $args{attributes}->{QueryModel} || 
      $args{attributes}->{BodyModel} ||
      $args{attributes}->{BodyModelFor}; 
  return @roles;
};

__PACKAGE__->meta->make_immutable;