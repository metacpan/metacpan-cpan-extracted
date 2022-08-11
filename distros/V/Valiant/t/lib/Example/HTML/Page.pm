package Example::HTML::Page;

use Moo;
use Example::HTML 'Hello', 'Layout';
use Valiant::HTML::TagBuilder 'p';

with 'Valiant::HTML::Component';

has 'name' => (is=>'ro', required=>1);

sub render {
  my ($self) = @_;

  return  Layout +{ page_title=>'Layout1' }, sub {
            my $layout = shift;
            $layout->top(
              p [
                p 111,
                p 222,
              ]
            );
            return Hello +{ name=>$self->name },
            p +{ id=>1 },
            "Truth! Justice!";
  };
}

1;
