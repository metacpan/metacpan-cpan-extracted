#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2012-2013 -- leonerd@leonerd.org.uk

package Circle::FE::Term::Ribbon;

use strict;
use warnings;

use base qw( Tickit::Widget::Tabbed::Ribbon );

package Circle::FE::Term::Ribbon::horizontal;
use base qw( Circle::FE::Term::Ribbon );

use feature qw( switch );
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

use Tickit::Utils qw( textwidth );
use List::Util qw( max first );
Tickit::Widget->VERSION( '0.35' ); # ->render_to_rb

use Tickit::Style;

style_definition base =>
   activity_fg => "cyan";

use constant orientation => "horizontal";

sub lines { 1 }
sub cols  { 1 }

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   my $win = $self->window or return;

   my @tabs = $self->tabs;
   my $active = $self->active_tab;

   $rb->goto( 0, 0 );

   my $col = 0;
   my $printed;

   if( $active ) {
      $rb->text( $printed = sprintf( "%d", $active->index + 1 ), $active->pen );
      $col += textwidth $printed;

      $rb->text( $printed = sprintf( ":%s | ", $active->label ) );
      $col += textwidth $printed;
   }

   my $rhs = sprintf " | total: %d", scalar @tabs;
   my $rhswidth = textwidth $rhs;

   $self->{tabpos} = \my @tabpos;

   if( grep { $_ != $active and $_->level > 0 } @tabs ) {
      my @used;
      # Output formats: [0] = full text
      #                 [1] = initialise level<2 names
      #                 [2] = initialise level<3 names
      #                 [3] = initialise all names
      #                 [4] = hide level<2 names, initialise others
      #                 [5] = hide all names

      foreach my $idx ( 0 .. $#tabs ) {
         my $tab = $tabs[$idx];
         next if $tab == $active;

         next unless my $level = $tab->level;

         my $width_full  = textwidth sprintf "%d:%s", $idx + 1, $tab->label;
         my $width_short = textwidth sprintf "%d:%s", $idx + 1, $tab->label_short;
         my $width_hide  = textwidth sprintf "%d", $idx + 1;

         $used[0] += 1 +              $width_full;
         $used[1] += 1 + $level < 2 ? $width_short : $width_full;
         $used[2] += 1 + $level < 3 ? $width_short : $width_full;
         $used[3] += 1 +              $width_short;
         $used[4] += 1 + $level < 2 ? $width_hide : $width_short;
         $used[5] += 1 +              $width_hide;
      }

      my $space = $win->cols - $col - $rhswidth;

      my $format;
      given( Circle::FE::Term->get_theme_var( "label_format" ) ) {
         when( "name_and_number" ) { $format = 0 }
         when( "initial" )         { $format = 3 }
         when( "number" )          { $format = 5 }
         default                   { die "Unrecognised label_format $_"; $format = 0 }
      }

      $format++ while $format < $#used and $used[$format] > $space;

      my $first = 1;

      TAB: foreach my $idx ( 0 .. $#tabs ) {
         my $tab = $tabs[$idx];
         next if $tab == $active;

         next unless my $level = $tab->level;

         my $label;

         for( $format ) {
            $label =             sprintf "%d:%s", $idx + 1, $tab->label;
            when( 0 ) { ; }
            when( 1 ) { $label = sprintf "%d:%s", $idx + 1, $tab->label_short if $level < 2 }
            when( 2 ) { $label = sprintf "%d:%s", $idx + 1, $tab->label_short if $level < 3 }
            $label =             sprintf "%d:%s", $idx + 1, $tab->label_short;
            when( 3 ) { ; }
            when( 4 ) { $label = sprintf "%d", $idx + 1 if $level < 2 }
            when( 5 ) { $label = sprintf "%d", $idx + 1 }
         }

         {
            $rb->savepen;

            if( !$first ) {
               $rb->setpen( $self->get_style_pen( "activity" ) );
               $rb->text( "," );
               $col++;
            }

            $rb->setpen( $tab->pen );
            $rb->text( $label );
            my $width = textwidth $label;

            push @tabpos, [ $idx, $col, $width ]; 

            $col += $width;

            $rb->restore;
         }

         $first = 0;
      }
   }

   $rb->erase_to( $win->cols - $rhswidth );

   $rb->text( $rhs );
}

sub scroll_to_visible { }

sub activate_next
{
   my $self = shift;

   my @tabs = $self->tabs;
   @tabs = ( @tabs[$self->active_tab_index + 1 .. $#tabs], @tabs[0 .. $self->active_tab_index - 1] );

   my $max_level = max map { $_->level } @tabs;
   return unless $max_level > 0;

   my $next_tab = first { $_->level == $max_level } @tabs;

   $next_tab->activate if $next_tab;
}

my $tab_shortcuts = "1234567890" .
                    "qwertyuiop" .
                    "sdfghjkl;'" .
                    "zxcvbnm,./";

sub on_key
{
   my $self = shift;
   my ( $ev ) = @_;

   if( $ev->type eq "key" and $ev->str eq "M-a" ) {
      $self->activate_next;
      return 1;
   }
   elsif( $ev->type eq "key" and $ev->str =~ m/^M-(.)$/ and
          ( my $idx = index $tab_shortcuts, $1 ) > -1 ) {
      eval { $self->activate_tab( $idx ) }; # ignore croak on invalid index
      return 1;
   }

   return 0;
}

sub on_mouse
{
   my $self = shift;
   my ( $ev ) = @_;

   return 0 unless $ev->line == 0;

   if( $ev->type eq "press" and $ev->button == 1 ) {
      foreach my $pos ( @{ $self->{tabpos} } ) {
         $self->activate_tab( $pos->[0] ), return 1 if $ev->col >= $pos->[1] and $ev->col < $pos->[1] + $pos->[2];
      }
   }
   elsif( $ev->type eq "wheel" ) {
      $self->prev_tab if $ev->button eq "up";
      $self->next_tab if $ev->button eq "down";
      return 1;
   }
}

0x55AA;
