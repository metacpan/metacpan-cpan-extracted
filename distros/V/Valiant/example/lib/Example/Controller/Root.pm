package Example::Controller::Root;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;

extends 'Catalyst::Controller';

sub root :Chained(/) PathPart('') CaptureArgs(0) ($self, $c) { }

  sub not_found :Chained(root) PathPart('') Args ($self, $c, @args) {
    return $c->detach_error(404, +{error=>"Requested URL not found: @{[ $c->req->uri ]}"});
  }

  sub static :GET Chained(root) PathPart('static') Args {
    my ($self, $c, @args) = @_;
    return $c->serve_file('static', @args) // $c->detach_error(404, +{error=>"Requested URL not found: @{[ $c->req->uri ]}"});
  }

  sub unauth :Chained(root) PathPart('') CaptureArgs() ($self, $c) {
    return $c->next_action($c->user);
  }
  
  sub auth :Chained(root) PathPart('') CaptureArgs() ($self, $c) {
    return $c->next_action($c->user) if $c->user->authenticated;
    return $c->detach('#login'); 
  }

sub end :Action Does(RenderErrors) Does(RenderView) { }  # The order of the Action Roles is important!!

__PACKAGE__->config(namespace=>'');
__PACKAGE__->meta->make_immutable;
