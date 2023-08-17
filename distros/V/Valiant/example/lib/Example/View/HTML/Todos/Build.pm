package Example::View::HTML::Todos::Build;

use Moo;
use Example::Syntax;
use Example::View::HTML
  -tags => qw(div a fieldset form_for),
  -util => qw(path),
  -views => 'HTML::Page', 'HTML::Navbar', 'HTML::Todos::Form';

has 'todo' => (is=>'ro', required=>1, handles=>[qw/status_options/] );

sub render($self, $c) {
  html_page page_title=>'Homepage', sub($page) {
    html_navbar active_link=>'todo_list',
    div +{ class=>'col-5 mx-auto' },
      html_todos_form todo=>$self->todo,
  };
}

1;
