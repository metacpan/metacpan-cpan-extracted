package View::Example::View;

use Moo;
use Catalyst::View::Valiant
  -tags => qw(blockquote label_tag);

sub stuff2 {
  my $self = shift;
  $self->label_tag('test', sub {
    my $view = shift;
    die unless ref($view) eq ref($self);
  });
  return $self->tags->div('stuff2');
}

sub stuff3 :Renders {
  blockquote 'stuff3', 
  shift->div('stuff333')
}

1;