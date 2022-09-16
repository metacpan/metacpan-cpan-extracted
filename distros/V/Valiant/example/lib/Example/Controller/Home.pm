package Example::Controller::Home;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;

extends 'Example::Controller';

## This is an example of how to handle the case when you want the same URL endpoint to
## display one page if the user is logged in and a different one if not.

sub root :Chained(../unauth) PathPart('') CaptureArgs(0) ($self, $c, $user) { }

  # Nothing here for now so just redirect to login
  sub public_home :GET Chained(root) PathPart('') Args(0) ($self, $c) {
    return $c->redirect_to_action('#login') && $c->detach;
  }

  sub user_home :GET Chained(root) PathPart('') Args(0) Name(home) Does(Authenticated) ($self, $c) {
    $c->view('HTML::Home');
    $c->view->info('The time is '. localtime);
  }

__PACKAGE__->meta->make_immutable;
