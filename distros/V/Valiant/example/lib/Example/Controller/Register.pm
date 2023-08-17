package Example::Controller::Register;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;

extends 'Example::Controller';

sub root :At('$path_end/...') Via('../public')  ($self, $c, $user) {
  return $c->redirect_to_action('/home/user_show') && $c->detach if $user->registered;
  $c->action->next($user);
}

  sub prepare_build :At('...') Via('root') ($self, $c, $user) {
    $self->view_for('build', registration => $user); 
    $c->action->next($user);
  }

    # GET /register/new
    sub build :Get('new') Via('prepare_build') ($self, $c, $user) { return }

    # POST /register
    sub create :Post('') Via('prepare_build') BodyModel ($self, $c, $user, $bm) {
      return $c->redirect_to_action('/session/build') if $user->register($bm);
    }

__PACKAGE__->meta->make_immutable; 
