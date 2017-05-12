#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2010-2015 -- leonerd@leonerd.org.uk

package Circle::FE::Term::Widget::Entry;

use strict;
use constant type => "Entry";

sub build
{
   my $class = shift;
   my ( $obj, $tab ) = @_;

   my $autoclear = $obj->prop("autoclear");

   my $prehistory;
   my $history_index;

   my $pending_count = 0;

   my $widget = Circle::FE::Term::Widget::Entry::Widget->new(
      classes => $obj->prop( "classes" ),
      tab => $tab,

      on_enter => sub {
         my ( $self, $line ) = @_;

         $pending_count++;
         $self->send_pending( $pending_count );

         $tab->adopt_future(
            $obj->call_method(
               enter => $self->text,
            )->on_done( sub {
               $pending_count--;
               $self->send_pending( $pending_count );
            })->on_fail( sub {
               my ( $message ) = @_;
               # TODO: write the error message somewhere
               $pending_count--;
               $self->send_pending( $pending_count );
            })
         );

         $self->set_text( "" ) if $autoclear;
         undef $history_index;
      },
   );

   $tab->adopt_future(
      $obj->watch_property_with_initial(
         "text",
         on_set => sub {
            my ( $text ) = @_;
            $text = "" unless defined $text;
            $widget->set_text( $text );
         },
      )
   );

   $tab->adopt_future(
      $obj->watch_property_with_initial(
         "history",
         on_updated => sub {}, # We ignore this, we just want a local cache
      )
   );

   $tab->adopt_future(
      $obj->watch_property_with_initial(
         "completions",
         on_updated => sub {}, # We ignore this, we just want a local cache
      )
   );

   $widget->bind_keys(
      Up => sub {
         my $widget = shift;

         my $history = $obj->prop("history");
         if( !defined $history_index ) {
            $prehistory = $widget->text;
            return 1 unless @$history;
            $history_index = $#$history;
         }
         elsif( $history_index == 0 ) {
            # Don't move
            return 1;
         }
         else {
            $history_index--;
         }

         my $line = $history->[$history_index];
         $widget->set_text( $line );
         $widget->set_position( length( $line ) ); # TODO: accept negative

         return 1;
      },
      Down => sub {
         my $widget = shift;

         my $history = $obj->prop("history");
         return 1 unless defined $history_index;
         if( $history_index < $#$history ) {
            $history_index++;
         }
         else {
            $widget->set_text( $prehistory );
            undef $history_index;
            return 1;
         }

         my $line = $history->[$history_index];
         $widget->set_text( $line );
         $widget->set_position( length( $line ) );

         return 1;
      },
   );

   $widget->{obj} = $obj;

   return $widget;
}

Tickit::Style->load_style( <<'EOF' );
Circle::FE::Term::Widget::Entry::Widget.topic {
  bg: "blue";
}

EOF

package Circle::FE::Term::Widget::Entry::Widget;

use base qw( Tickit::Widget::Entry );
Tickit::Window->VERSION( '0.42' );

use Tickit::Style -copy;

use constant KEYPRESSES_FROM_STYLE => 1;

style_definition base =>
   '<Tab>' => "tab_complete";

use Tickit::Utils qw( textwidth );
use List::Util qw( max );

use constant PEN_UNDER => Tickit::Pen->new( u => 1 );

sub new
{
   my $class = shift;
   my %args = @_;

   my $tab = delete $args{tab};

   my $self = $class->SUPER::new( %args );

   $self->{tab} = $tab;

   return $self;
}

sub on_key
{
   my $self = shift;
   my ( $ev ) = @_;

   $self->{tab}->activated;

   my $redo_tab_complete;
   if( my $popup = delete $self->{tab_complete_popup} ) {
      $popup->hide;
      $redo_tab_complete++
   }

   my $ret = $self->SUPER::on_key( @_ );

   if( $redo_tab_complete ) {
      if( $ev->type eq "text" or $ev->str eq "Backspace" ) {
         $self->key_tab_complete;
      }
   }

   return $ret;
}

sub key_tab_complete
{
   my $widget = shift;

   my $obj = $widget->{obj};

   my ( $partial ) = substr( $widget->text, 0, $widget->position ) =~ m/(\S*)$/;
   my $plen = length $partial or return 1;

   my $at_sol = ( $widget->position - $plen ) == 0;

   my @matches;
   my $matchgroup;
   foreach my $group ( values %{ $obj->prop("completions") } ) {
      next if $group->prop("only_at_sol") and not $at_sol;

      my @more = grep { $_ =~ m/^\Q$partial\E/i } @{ $group->prop("items") };

      push @matches, @more;
      $matchgroup = $group if @more;
   }

   return 1 unless @matches;

   my $add = $matches[0];
   foreach my $more ( @matches[1..$#matches] ) {
      # Find the common prefix
      my $diffpos = 1;
      $diffpos++ while lc substr( $add, 0, $diffpos ) eq lc substr( $more, 0, $diffpos );

      return 1 if $diffpos == 1;

      $add = substr( $add, 0, $diffpos - 1 );
   }

   if( @matches == 1 ) {
      # No others meaning only one initially
      $add .= ( $matchgroup->prop("suffix_sol") and $at_sol ) ? $matchgroup->prop("suffix_sol")
                                                              : " ";
   }

   $widget->text_splice( $widget->position - $plen, $plen, $add );

   if( @matches > 1 ) {
      # Split matches on next letter
      my %next;
      foreach ( @matches ) {
         my $l = substr( $_, $plen, 1 );
         push @{ $next{$l} }, $_;
      }

      my @possibles = map {
         @{ $next{$_} } == 1 ? $next{$_}[0]
                             : substr( $next{$_}[0], 0, $plen + 1 )."..."
      } sort keys %next;

      # TODO: Wrap these into a flow

      # TODO: need scrolloffs
      my $popup = $widget->window->make_popup(
         -(scalar @possibles), $widget->position - $widget->{scrolloffs_co} - $plen,
         scalar @possibles, max( map { textwidth($_) } @possibles ),
      );

      $popup->pen->chattrs({ bg => 'green', fg => 'black' });

      $popup->bind_event( expose => sub {
         my ( $win, undef, $info ) = @_;
         my $rb = $info->rb;

         foreach my $line ( 0 .. $#possibles ) {
            my $str = $possibles[$line];

            $rb->goto( $line, 0 );

            $rb->text( substr( $str, 0, $plen + 1 ), PEN_UNDER );
            $rb->text( substr( $str, $plen + 1 ) ) if length $str > $plen + 1;
            $rb->erase_to( $win->cols );
         }
      } );

      $popup->show;

      $widget->{tab_complete_popup} = $popup;
   }

   return 1;
}

sub send_pending
{
   my $self = shift;
   my ( $count ) = @_;

   $self->{pending_count} = $count;

   if( $count ) {
      my $win = $self->{pending_window} ||= do {
         my $win = $self->window->make_hidden_sub( 0, $self->window->cols - 12, 1, 12 );
         my $countr = \$self->{pending_count};
         $win->bind_event( expose => sub {
            my ( $win, undef, $info ) = @_;
            my $rb = $info->rb;

            $rb->goto( 0, 0 );
            $rb->text( "Sending $$countr..." );
            $rb->erase_to( 12 );
         });
         $win->pen->chattrs({ fg => "black", bg => "cyan", i => 1 });
         $win;
      };

      if( !$win->is_visible ) {
         # TODO: Use Tickit->timer when it comes out
         $win->tickit->loop->watch_time( after => 0.5, code => sub {
            $win->show if $self->{pending_count} and !$win->is_visible;
         });
      }

      $win->expose if $win->is_visible;
   }
   elsif( my $win = $self->{pending_window} ) {
      $win->hide;
   }
}

0x55AA;
