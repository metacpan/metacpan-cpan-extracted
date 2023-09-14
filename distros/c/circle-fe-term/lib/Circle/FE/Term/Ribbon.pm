#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2012-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad;

package Circle::FE::Term::Ribbon 0.232470;

use base qw( Tickit::Widget::Tabbed::Ribbon );

class Circle::FE::Term::Ribbon::horizontal
   :isa(Tickit::Widget::Tabbed::Ribbon::horizontal);

use Syntax::Keyword::Match;

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
      #                 [6] = hide all names, hide level<2 tabs entirely
      #                 [7] = hide all names, hide level<3 tabs entirely

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
         $used[6] += 1 +              $width_hide                if $level >= 2;
         $used[7] += 1 +              $width_hide                if $level >= 3;
      }

      my $space = $win->cols - $col - $rhswidth;

      my $format;
      match( Circle::FE::Term->get_theme_var( "label_format" ) : eq ) {
         case( "name_and_number" ) { $format = 0 }
         case( "initial" )         { $format = 3 }
         case( "number" )          { $format = 5 }
         default                   { die "Unrecognised label_format $_"; $format = 0 }
      }

      $format++ while $format < $#used and $used[$format] > $space;

      my $first = 1;
      my $hiddencount = 0;

      TAB: foreach my $idx ( 0 .. $#tabs ) {
         my $tab = $tabs[$idx];
         next if $tab == $active;

         next unless my $level = $tab->level;

         my $label;
         match( $format : == ) {
            case( 0 ) { $label =              $tab->label }
            case( 1 ) { $label = $level < 2 ? $tab->label_short : $tab->label }
            case( 2 ) { $label = $level < 3 ? $tab->label_short : $tab->label }
            case( 3 ) { $label =              $tab->label_short }
            case( 4 ) { $label = $level < 2 ? undef             : $tab->label_short }
            case( 5 ) { }
            case( 6 ) { $level >= 2 or $hiddencount++, next TAB }
            case( 7 ) { $level >= 3 or $hiddencount++, next TAB }
         }

         my $text = sprintf "%d", $idx + 1;
         $text .= ":$label" if defined $label;

         {
            $rb->savepen;

            if( !$first ) {
               $rb->setpen( $self->get_style_pen( "activity" ) );
               $rb->text( "," );
               $col++;
            }

            $rb->setpen( $tab->pen );
            $rb->text( $text );
            my $width = textwidth $text;

            push @tabpos, [ $idx, $col, $width ]; 

            $col += $width;

            $rb->restore;
         }

         $first = 0;
      }

      if( $hiddencount ) {
         $rb->savepen;
         $rb->setpen( Circle::FE::Term->get_theme_pen( "level1" ) );
         $rb->text( " + $hiddencount more" );
         $rb->restore;
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
