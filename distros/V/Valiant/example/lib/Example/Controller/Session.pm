package Example::Controller::Session;

use CatalystX::Moose;
use Example::Syntax;

extends 'Example::Controller';

has person => (is=>'ro', shared=>1, default=>sub { shift->ctx->user });

sub root :At('login/...') Via('../root') ($self, $c) {
  return $c->redirect_to_action('/home/user_show') && $c->detach
    if $self->person->authenticated;
}

  sub prepare_build :At('...') Via('root') QueryModel ($self, $c, $q) {
    return $self->view_for('build', ($q->has_replace ? (replace=>$q->replace) : ())); 
  }

    # GET /login/new
    sub build :Get('new') Via('prepare_build') ($self, $c) { }

    # POST /login
    sub create :Post('') Via('prepare_build') BodyModel ($self, $c, $bm) {
      return $self->view->redirect_to_action('/home/user_show')
        if $c->authenticate($self->person, $bm);
    }

# GET /logout
sub logout :Get('logout') Via('../protected') ($self, $c) {
  return $c->logout && $c->redirect_to_action('build');
}

__PACKAGE__->meta->make_immutable;