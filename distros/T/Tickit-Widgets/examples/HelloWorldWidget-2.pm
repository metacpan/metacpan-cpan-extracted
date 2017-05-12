package HelloWorldWidget;
use base 'Tickit::Widget';

sub lines {  1 }
sub cols  { 12 }

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   my $win = $self->window;

   $rb->eraserect( $rect );

   $rb->text_at( ( $win->lines - 1 ) / 2, ( $win->cols - 12 ) / 2,
      "Hello, world"
   );
}

1;
