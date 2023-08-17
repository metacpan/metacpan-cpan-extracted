package Example::Controller::Root;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;

extends 'Example::Controller';

sub root :At('/...') ($self, $c) {
  $c->action->next($c->user);
}

  sub not_found :At('/{*}') Via('root') ($self, $c, $user, @args) {
    return $c->detach_error(404, +{error=>"Requested URL not found: @{[ $c->req->uri ]}"});
  }

  sub public :At('/...') Via('root') ($self, $c, $user) {
    $c->action->next($user);
  }

    sub static :Get('static/{*}') Via('public') ($self, $c, $user, @args) {
      return $c->serve_file('static', @args) // $c->detach_error(404, +{error=>"Requested URL not found."});
    }
  
  sub protected :At('/...') Via('root') ($self, $c, $user) {
    return $c->redirect_to_action('/session/build') && $c->detach unless $user->authenticated;
    $c->action->next($user); 
  }

sub end :Action Does('RenderErrors') Does('RenderView') { }  # The order of the Action Roles is important!!

__PACKAGE__->config(namespace=>'');
__PACKAGE__->meta->make_immutable;
