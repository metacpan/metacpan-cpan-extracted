package Example::Controller::Root;

use Moose;
use MooseX::MethodAttributes;
use Example::Syntax;

extends 'Catalyst::Controller';

sub root :Chained(/) PathPart('') CaptureArgs(0) ($self, $c) { }

  sub not_found :Chained(root) PathPart('') Args ($self, $c, @args) {
    return $c->detach_error(404, +{error=>"Requested URL not found: @{[ $c->req->uri ]}"});
  }

  sub public :Chained(root) PathPart('public') Args {
    my ($self, $c, @args) = @_;
    return $c->serve_file('public', @args) || $c->detach_error(404);
  }
  
  sub auth: Chained(root) PathPart('') CaptureArgs() ($self, $c) {
    return if $c->user->authenticated;
    return $c->redirect_to_action('#login') && $c->detach;
  }

sub end :Action Does(RenderView) Does(RenderErrors) {}

__PACKAGE__->config(namespace=>'');
__PACKAGE__->meta->make_immutable;
