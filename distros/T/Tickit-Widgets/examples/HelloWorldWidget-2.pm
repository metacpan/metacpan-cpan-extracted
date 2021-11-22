use Object::Pad 0.57;

class HelloWorldWidget
   :isa(Tickit::Widget);

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
