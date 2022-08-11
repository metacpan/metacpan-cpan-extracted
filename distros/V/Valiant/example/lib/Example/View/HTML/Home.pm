package Example::View::HTML::Home;

use Moose;
use Example::Syntax;
use Valiant::HTML::TagBuilder 'div', 'blockquote', 'cond';

extends 'Example::View::HTML';

has info => (is=>'rw', predicate=>'has_info');

sub render($self, $c) {
  $c->view('HTML::Layout' => page_title=>'Homepage', sub($layout) {
    $c->view('HTML::Navbar' => active_link=>'/'),
    cond { $self->has_info } sub {
      blockquote +{ class=>"alert alert-primary", role=>"alert" }, $self->info,
    },
    div 'Welcome to your Example application Homepage';
  });
}

__PACKAGE__->meta->make_immutable();
