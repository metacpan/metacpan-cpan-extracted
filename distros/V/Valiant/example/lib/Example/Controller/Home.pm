package Example::Controller::Home;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;

extends 'Example::Controller';

## This is an example of how to handle the case when you want the same URL endpoint to
## display one page if the user is logged in and a different one if not.

sub root :Via(*Public) At('/...') ($self, $c, $user) { }

  # Nothing here for now so just redirect to login
  sub public_home :GET Via('root') At('') ($self, $c) {
    return $c->redirect_to_action('*Login') && $c->detach;
  }

  sub user_home :GET Via('root') At('') Name(Home) Does(Authenticated) ($self, $c) {
    $c->view('HTML::Home');
    $c->view->info('The time is '. localtime);
  }

__PACKAGE__->meta->make_immutable;
