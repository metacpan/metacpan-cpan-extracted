package Example::View::Errors::HTML;

use Moose;
use Example::Syntax;

extends 'Catalyst::View::Errors::HTML';

sub http_default($self, $c, $code, %args) {
  return $c->view('HTML::Errors::Default', status_code=>$code, %args);
}

sub http_404($self, $c, %args) {
  return $c->view('HTML::Errors::NotFound', %args);
}

sub http_403($self, $c, %args) {
  $c->user->errors->add(undef, 'You must be logged in to see this page.');
  return $c->view('HTML::Login', user=>$c->user, post_login_redirect=>$c->req->uri);
}

__PACKAGE__->meta->make_immutable;
