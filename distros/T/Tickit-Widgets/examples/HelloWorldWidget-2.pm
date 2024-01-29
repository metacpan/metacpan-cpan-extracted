use v5.20;
use warnings;
use Object::Pad 0.807;

class HelloWorldWidget;

inherit Tickit::Widget;

method lines {  1 }
method cols  { 12 }

method render_to_rb
{
   my ( $rb, $rect ) = @_;

   my $win = $self->window;

   $rb->eraserect( $rect );

   $rb->text_at( ( $win->lines - 1 ) / 2, ( $win->cols - 12 ) / 2,
      "Hello, world"
   );
}

1;
