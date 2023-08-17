package Example::Controller::Session;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;

extends 'Example::Controller';

has post_login_action => (is=>'ro', isa=>'Str', default=>'/home/user_show');

sub root :At('login/...') Via('../root') ($self, $c, $user) {
  return $c->redirect_to_action($self->post_login_action) && $c->detach
    if $user->authenticated;
  $c->action->next($user);
}

  sub prepare_build :At('...') Via('root') ($self, $c, $user) {
    $self->view_for('build', user => $user); 
    $c->action->next($user);
  }

    # GET /login/new
    sub build :Get('new') Via('prepare_build') ($self, $c, $user) {   }

    # POST /login
    sub create :Post('') Via('prepare_build') BodyModel ($self, $c, $user, $bm) {
      return $c->redirect_to_action($self->post_login_action)
        if $c->authenticate($user, $bm);
    }

# GET /logout
sub logout :Get('logout') Via('../protected') ($self, $c, $user) {
  return $c->logout && $c->redirect_to_action('build');
}

__PACKAGE__->meta->make_immutable;
