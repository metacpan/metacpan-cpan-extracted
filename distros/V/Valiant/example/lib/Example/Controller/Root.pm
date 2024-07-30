package Example::Controller::Root;

use CatalystX::Moose;
use Example::Syntax;

extends 'Example::Controller';

sub root :At('/...') ($self, $c) { }

  sub not_found :At('/{*}') Via('root') ($self, $c, @args) {
    return $c->detach_error(404, +{error=>"Requested URL not found: @{[ $c->req->uri ]}"});
  }

  sub public :At('/...') Via('root') ($self, $c) { }

    sub static :Get('static/{*}') Via('public') ($self, $c, @args) {
      return $c->serve_file('static', @args) // $c->detach_error(404, +{error=>"Requested URL not found."});
    }
  
  sub protected :At('/...') Via('root') ($self, $c) {
    return $c->redirect_to_action('/session/build') && $c->detach
      unless $c->user->authenticated;
  }

sub end :Action Does('RenderErrors') Does('RenderView') { }  # The order of the Action Roles is important!!

__PACKAGE__->config(namespace=>'');
__PACKAGE__->meta->make_immutable;
