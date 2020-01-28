#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package Tickit::App::Plugin::EscapePrefix;

use strict;
use warnings;

our $VERSION = '0.01';

use Tickit 0.64 qw( MOD_ALT );
use Tickit::Term qw( BIND_FIRST );

=head1 NAME

C<Tickit::App::Plugin::EscapePrefix> - C<Tickit> application plugin for Escape-prefixed shortcut keys

=head1 SYNOPSIS

   use Tickit;
   use Tickit::App::Plugin::EscapePrefix;

   my $tickit = Tickit->new;

   Tickit::App::Plugin::EscapePrefix->apply( $tickit );

   ...

   $tickit->run;

=head1 DESCRIPTION

This package applies code to a L<Tickit> instance to let it handle
C<< <Escape > >>-prefixed shortcut keys, by converting them into the
equivalent C<< <M-...> >> modified keys instead.

Once applied using the L</apply> method, the plugin will consume any plain
C<< <Escape> >> keys typed at the terminal. If another key arrives soon
afterwards, this key will be consumed and instead a new keypress event emitted
that adds the "meta" modifier to it. For example, typing C<< <Escape> <a> >>
will instead emit the modified key C<< <M-a> >> to the application. If no
subsequent key arrives after a timeout of 3 seconds then the modification will
not apply.

While the plugin is still pending anothey keypress to modify, a small
indicator window will appear in the bottom left of the display, showing
C<ESC-> in a reverse-video style, to remind the user the keypress is pending.

=cut

=head1 METHODS

=cut

=head2 apply

   Tickit::App::Plugin::EscapePrefix->apply( $tickit )

Applies the plugin code to the given toplevel L<Tickit> instance.

=cut

sub apply
{
   my $pkg = shift;
   my ( $t ) = @_;

   my $esc_held;
   my $esc_indicator_window = $t->rootwin->make_float( 0, 0, 1, 4 );
   $esc_indicator_window->hide;
   $esc_indicator_window->pen->chattr( rv => 1 );
   $esc_indicator_window->bind_event( expose => sub {
      my ( $win, undef, $info ) = @_;
      $info->rb->text_at( 0, 0, "ESC-" );
   } );

   my $timer_id;

   $t->term->bind_event( key => BIND_FIRST, sub {
      my ( $term, $ev, $info ) = @_;

      if( $esc_held ) {
         $esc_held = 0;
         $esc_indicator_window->hide;
         $t->cancel_timer( $timer_id ) if defined $timer_id;
         undef $timer_id;

         $term->emit_key(
            type => "key",
            str  => "M-" . $info->str,
            mod  => $info->mod | MOD_ALT,
         );

         return 1;
      }

      if( $info->type eq "key" and $info->str eq "Escape" ) {
         $esc_held = 1;
         $esc_indicator_window->reposition( $t->rootwin->lines - 1, 0 );
         $esc_indicator_window->show;

         $t->cancel_timer( $timer_id ) if defined $timer_id;
         $timer_id = $t->timer( after => 3, sub {
            $esc_held = 0;
            $esc_indicator_window->hide;
            undef $timer_id;
         } );

         return 1;
      }

      return 0;
   } );
}

=head1 TODO

=over 4

Much configuration - timeout; style, text and position of indicator window

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
