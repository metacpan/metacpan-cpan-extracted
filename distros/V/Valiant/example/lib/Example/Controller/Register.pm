package Example::Controller::Register;

use CatalystX::Moose;
use Example::Syntax;

extends 'Example::Controller';

has registration => (is=>'rw', context=>'user');

sub root :At('$path_end/...') Via('../public')  ($self, $c) {
  return $c->redirect_to_action('/home/user_show') && $c->detach
    if $self->registration->registered;
}

  sub prepare_build :At('...') Via('root') QueryModel ($self, $c, $q) {
    return $self->view_for('build', ($q->has_replace ? (replace=>$q->replace) : ()));
  }

    # GET /register/new
    sub build :Get('new') Via('prepare_build') ($self, $c) { return }

    # POST /register
    sub create :Post('') Via('prepare_build') BodyModel ($self, $c, $bm) {
      return $self->view->redirect_to_action('/session/build')
        if $self->registration->register($bm);
    }

__PACKAGE__->meta->make_immutable; 