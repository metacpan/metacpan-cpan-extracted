package Example::HTML::Layout;

use Moo;
use Valiant::HTML::TagBuilder ':html';

with 'Valiant::HTML::ContentComponent';

has 'page_title' => (is=>'rw', required=>1);
has 'top' => (is=>'rw', required=>1, default=>sub { "test<p>" });

sub render {
  my ($self, $inner) = @_;
  return  html [
            $self->top,
            head
              title $self->page_title,
            body $inner
          ];
}

1;
