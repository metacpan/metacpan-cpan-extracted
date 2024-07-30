package Example::Controller::Home;

use CatalystX::Moose;
use Example::Syntax;

extends 'Example::Controller';

## This is an example of how to handle the case when you want the same URL endpoint to
## display one page if the user is logged in and a different one if not. In chaining
## we check the last matching action first so put the 'catchall' nearer the top of the
## of the controller.

sub root :At('/...') Via('../public')  ($self, $c) { }

  # GET /
  sub public_show :Get('') Via('root') ($self, $c) {
    # Nothing here for now so just redirect to login
    return $c->redirect_to_action('/session/build') && $c->detach;
  }

  # GET /
  sub user_show :Get('') Via('root') Does(Authenticated) ($self, $c) {
    return $self->view
      ->add_info("Welcome to your home page!")
      ->add_info('The time is '. localtime); # This is just to show how to use the view object
  }

  # GET /js/test
  sub js_test :Get('js/test') Via('root') Does(Authenticated) ($self, $c) {
    return $self->view(name=>'John Doe');
  }

__PACKAGE__->meta->make_immutable;
