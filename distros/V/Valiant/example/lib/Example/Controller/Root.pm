package Example::Controller::Root;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;

extends 'Example::Controller';

sub root :At('/...') Name(Root) ($self, $c) {
  $c->action->next($c->user);
}

  sub not_found :Via('root') At('/{*}')  ($self, $c, $user, @args) {
    return $c->detach_error(404, +{error=>"Requested URL not found: @{[ $c->req->uri ]}"});
  }

  sub static :GET Via('root') At('static/{*}') ($self, $c, $user, @args) {
    return $c->serve_file('static', @args) // $c->detach_error(404, +{error=>"Requested URL not found."});
  }

  sub public :Via('root') At('/...') Name(Public) ($self, $c, $user) {
    $c->action->next($user);
  }
  
  sub private :Via('root') At('/...') Name(Private) ($self, $c, $user) {
    return $c->action->next($user) if $user->authenticated;
    return $c->redirect_to_action('*Login', +{post_login_redirect=>$c->req->uri}) && $c->detach;
  }

sub end :Action Does(RenderErrors) Does(RenderView) { }  # The order of the Action Roles is important!!

__PACKAGE__->config(namespace=>'');
__PACKAGE__->meta->make_immutable;
