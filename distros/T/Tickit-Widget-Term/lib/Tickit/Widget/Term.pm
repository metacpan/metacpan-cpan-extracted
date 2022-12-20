#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2022 -- leonerd@leonerd.org.uk

use v5.26; # signatures
use Object::Pad 0.73 ':experimental(init_expr)';

use Syntax::Keyword::Match;

package Tickit::Widget::Term 0.006;
class Tickit::Widget::Term
   :strict(params)
   :isa(Tickit::Widget);

use constant WIDGET_PEN_FROM_STYLE => 1;
use constant KEYPRESSES_FROM_STYLE => 1;
use constant CAN_FOCUS => 1;

use List::Util qw( min max );

use Tickit 0.71;  # ->watch_io
use Tickit::Style;

BEGIN {
   style_definition base =>
      '<Tab>'   => "",
      '<S-Tab>' => "";
}

use Term::VTerm;
use Term::VTerm::Pos;

use Convert::Color::RGB8;
use Convert::Color::XTerm;

=head1 NAME

C<Tickit::Widget::Term> - a widget containing a virtual terminal

=head1 SYNOPSIS

   use Tickit;
   use Tickit::Widget::Term;

   my $tickit = Tickit->new(
      root => my $term = Tickit::Widget::Term->new,
   );

   $term->set_on_output( sub {
      my ( $bytes ) = @_;
      ## some application logic here to handle the bytes
   });

   ## some application logic here to invoke $term->write_input

   $tickit->run;

=head1 DESCRIPTION

This widget class uses L<Term::VTerm> to provide a virtual terminal, receiving
bytes containing terminal sequences which are used to draw the content to the
screen.

Typically this would be used connected to some external process via a PTY
device. The L</use_pty> method can be used to connect this PTY device to the
widget. Alternatively, the application can perform this bytewise IO itself, via
the L</write_input> method and L</set_on_output> event handler.

=cut

# TODO: Perhaps Term::VTerm should provide this
my %VTERM_NAME_FROM_PROP =
   map { Term::VTerm->can( $_ )->() => lc +( $_ =~ m/^PROP_(.*)$/ )[0] }
   grep { m/^PROP_[A-Z]+$/ }
   do { no strict 'refs'; keys %{"Term::VTerm::"} };

my %CURSORSHAPE_MAP = (
   Term::VTerm::PROP_CURSORSHAPE_BLOCK     => Tickit::Term::CURSORSHAPE_BLOCK,
   Term::VTerm::PROP_CURSORSHAPE_UNDERLINE => Tickit::Term::CURSORSHAPE_UNDER,
   Term::VTerm::PROP_CURSORSHAPE_BAR_LEFT  => Tickit::Term::CURSORSHAPE_LEFT_BAR,
);

sub lines { 1 }
sub cols { 1 }

my %colcache;
sub _coltopen ( $name, $col )
{
   return ( $name => -1 ) if $name eq "fg" and $col->is_default_fg;
   return ( $name => -1 ) if $name eq "bg" and $col->is_default_bg;

   return ( $name => $col->index ) if $col->is_indexed;

   my $rgb = $col->rgb_hex;

   my $index = $colcache{$rgb} //= Convert::Color::RGB8->new( $col->red, $col->green, $col->blue )
      ->as_xterm->index;

   return (
      $name => $index,
      "${name}:rgb8" => "#" . $col->rgb_hex,
   );
}

field $_vterm;
field $_screen;

ADJUST
{
   $_vterm = Term::VTerm->new(
      rows => 1,
      cols => 1, # will be set by reshape
   );
   $_vterm->set_utf8( 1 );

   $_screen = $_vterm->obtain_screen;
   $_screen->set_callbacks(
      on_damage => sub ( $vtrect ) {
         my $window = $self->window or return 1;

         $window->expose( Tickit::Rect->new(
            top    => $vtrect->start_row,
            bottom => $vtrect->end_row,
            left   => $vtrect->start_col,
            right  => $vtrect->end_col,
         ) );

         return 1;
      },
      on_moverect => sub ( $dest, $src ) {
         my $window = $self->window or return 1;

         $window->scrollrect(
            Tickit::Rect->new(
               top    => min( $dest->start_row, $src->start_row ),
               bottom => max( $dest->end_row,   $src->end_row ),
               left   => min( $dest->start_col, $src->start_col ),
               right  => max( $dest->end_col,   $src->end_col ),
            ),
            $src->start_row - $dest->start_row,
            $src->start_col - $dest->start_col,
         );

         return 1;
      },
      on_movecursor => sub ( $pos, $, $visible ) {
         my $window = $self->window or return;

         $window->cursor_at( $pos->row, $pos->col );
         $window->setctl( "cursor-visible" => $visible );
      },
      on_settermprop => sub ( $prop, $value ) {
         my $window = $self->window or return;

         match( $prop : == ) {
            case( Term::VTerm::PROP_CURSORVISIBLE ) {
               $window->setctl( "cursor-visible" => !!$value );
            }
            case( Term::VTerm::PROP_CURSORBLINK ) {
               $window->setctl( "cursor-blink" => $value );
            }
            case( Term::VTerm::PROP_CURSORSHAPE ) {
               $window->setctl( "cursor-shape" => $CURSORSHAPE_MAP{ $value } );
            }
            case( Term::VTerm::PROP_MOUSE ) {
               # ignore
            }
            default {
               my $propname = $VTERM_NAME_FROM_PROP{$prop};
               print STDERR "TODO: termprop $propname($prop) = $value\n";
            }
         }
         1;
      },
      # TODO: on_bell
   );

   $_screen->enable_altscreen( 1 );
   $_screen->set_damage_merge( Term::VTerm::DAMAGE_SCREEN );
   $_screen->reset( 1 );
}

=head1 METHODS

=cut

=head2 write_input

   $term->write_input( $bytes )

Push more bytes into the terminal state.

=cut

method write_input ( $bytes )
{
   return $_vterm->input_write( $bytes );
}

=head2 on_output

=head2 set_on_output

   $on_output = $term->on_output

   $term->set_on_output( $on_output )

      $on_output->( $bytes )

Accessors for the C<on_output> event callback, which is invoked by the
terminal engine when more bytes of response have been generated.

Typically this is caused by keyboard or mouse events, but it can also be
generated in response to some received query sequences.

=cut

field $_on_output :reader :writer :param = undef;

=head2 flush

   $term->flush

Finishes a round of screen update events, ensuring that any pending screen
damage is handled. Also flushes the output buffer, invoking the C<on_event>
handler if required.

=cut

method flush ()
{
   $_screen->flush_damage;

   if( $_vterm->output_read( my $buf, 8192 ) ) {
      $_on_output->( $buf ) if $_on_output;
   }
}

=head2 on_resize

=head2 set_on_resize

   $on_resize = $term->on_resize

   $term->set_on_resize( $on_resize )

      $on_resize->( $lines, $cols )

Accessors for the C<on_resize> event callback, which is invoked after a resize
of the displayed widget. This may be required to inform the appliction driving
the terminal of its new output size.

=cut

field $_on_resize :reader :writer :param = undef;

# Various bits of PTY setup need access to the toplevel Tickit instance
# for its event loop handling. We might not have that yet.
# This structure lets us defer until we have one.

# TODO: That we have to do this at all suggests an API shape problem in
#   Tickit itself

field @_on_tickit;
method _on_tickit ( $code )
{
   if( my $win = $self->window ) {
      $code->( $win->tickit );
   }
   else {
      push @_on_tickit, $code;
   }
}

method window_gained ( $win )
{
   $self->SUPER::window_gained( $win );

   if( @_on_tickit ) {
      my $tickit = $self->window->tickit;
      ( shift @_on_tickit )->( $tickit ) while @_on_tickit;
   }
}

field $_pty;
field $_pty_read_watch;

=head2 use_pty

   $term->use_pty( $pty )

Takes an opened PTY device and sets up an IO watcher on it to receive bytes of
input. Additionally, arranges for output bytes to be sent to the handle.

This is a convenient alternative to feeding in bytes by calling
L</input_write> and receiving them with a callback set by L</set_on_output>.

The C<$pty> handle should be an L<IO::Pty> instance; or at least, well-behaved
as an IO handle and support the following methods:

   $pty->blocking( 0 );
   $pty->set_winsize( $lines, $cols );
   $pty->sysread( $buf, $len );
   $pty->syswrite( $buf );

=cut

method use_pty ( $pty )
{
   $_pty = $pty;

   $_pty->blocking( 0 );

   $self->_on_tickit( sub ( $tickit ) {
      $_pty_read_watch = $tickit->watch_io( $_pty, Tickit::IO_IN|Tickit::IO_HUP, sub ( $info ) {
         if( $info->cond & Tickit::IO_HUP ) {
            $tickit->watch_cancel( $_pty_read_watch );
            undef $_pty_read_watch;
            return;
         }

         my $buf;
         while(1) {
            $_pty->sysread( $buf, 8192 ) or last;
            $self->write_input( $buf );
         }
         $self->flush;
      } );
   } );

   $self->set_on_output( sub ( $buf ) {
      # TODO: Handle buffering of nonblocking writes returning EAGAIN
      $_pty->syswrite( $buf );
   } );

   $self->set_on_resize( sub ( $lines, $cols ) {
      $_pty->set_winsize( $lines, $cols );
   } );
}

method reshape ()
{
   my $win = $self->window or return;

   $_vterm->set_size( $win->lines, $win->cols );
   $_on_resize->( $win->lines, $win->cols ) if $_on_resize;
}

method render_to_rb ( $rb, $rect )
{
   foreach my $line ( $rect->linerange ) {
      foreach my $col ( $rect->left .. $rect->right - 1 ) {
         my $cell = $_screen->get_cell( Term::VTerm::Pos->new( row => $line, col => $col ) );
         my $str = $cell->str;

         unless( length $str ) {
            $rb->erase_at( $line, $col, 1, Tickit::Pen->new(
               _coltopen( bg => $cell->bg ),
            ) );
            next;
         }

         $rb->text_at( $line, $col, $str, Tickit::Pen->new(
            b => $cell->bold,
            u => $cell->underline,
            i => $cell->italic,
            rv => $cell->reverse,
            strike => $cell->strike,
            _coltopen( fg => $cell->fg ),
            _coltopen( bg => $cell->bg ),
         ) );
      }
   }
}

my %symcache;
sub _keynametosym ( $name )
{
   return $symcache{$name} //= do {
      my $func = Term::VTerm->can( "KEY_\U$name" );
      $func ? $func->() : 0;
   };
}

method on_key ( $ev )
{
   my $type = $ev->type;
   my $str  = $ev->str;

   # TODO: Tickit makes this really inconvenient
   my $basestr = $str;
   1 while $basestr =~ s/^[SCM]-//;

   my $codepoint = length $basestr == 1 ? ord $basestr : 0;

   if( $codepoint ) {
      $_vterm->keyboard_unichar( $codepoint, $ev->mod );
   }
   elsif( my $key = _keynametosym( $basestr ) ) {
      $_vterm->keyboard_key( $key, $ev->mod );
   }
   else {
      print STDERR "TODO: Convert $str into vterm constant\n";
   }

   $self->flush;

   return 1;
}

method on_mouse ( $ev )
{
   my $type = $ev->type;

   # TODO: $ev->mod
   my $mod = 0;

   $_vterm->mouse_move( $ev->line, $ev->col, $mod );

   if( $type eq "press" ) {
      $_vterm->mouse_button( $ev->button, 1, $mod );
   }
   elsif( $type eq "release" ) {
      $_vterm->mouse_button( $ev->button, 0, $mod );
   }
   elsif( $type eq "wheel" ) {
      my $button;
      $button = 4 if $ev->button eq "up";
      $button = 5 if $ev->button eq "down";
      $_vterm->mouse_button( $button, 1, $mod ) if $button;
   }

   $self->flush;

   return 1;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
