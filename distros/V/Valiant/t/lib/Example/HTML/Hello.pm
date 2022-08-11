package Example::HTML::Hello;

use Moo;
use Valiant::HTML::TagBuilder 'p';

with 'Valiant::HTML::Component';

has 'name' => (is=>'ro', required=>1);

sub render {
  my ($self) = @_;
  return p "Hello @{[ $self->name ]}";
}

1;
