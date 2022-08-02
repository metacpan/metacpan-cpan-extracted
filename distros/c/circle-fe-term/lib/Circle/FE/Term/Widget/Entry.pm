#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2010-2021 -- leonerd@leonerd.org.uk

package Circle::FE::Term::Widget::Entry;

use strict;
use constant type => "Entry";

use Tickit::Widget::Entry::Plugin::Completion;

sub build
{
   my $class = shift;
   my ( $obj, $tab ) = @_;

   my $autoclear = $obj->prop("autoclear");

   my $want_typing = $obj->can_property( "want_typing" ) && $obj->prop( "want_typing" );

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
               warn "Failed while sending text:\n$message";
               $pending_count--;
               $self->send_pending( $pending_count );
            })
         );

         $self->set_text( "" ) if $autoclear;
         undef $history_index;
      },

      ( $want_typing ? (
         on_typing => sub {
            my ( $typing ) = @_;
            $tab->adopt_future( $obj->call_method( typing => $typing ) );
         }
      ) : () ),
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

   Tickit::Widget::Entry::Plugin::Completion->apply( $widget,
      ignore_case => 1,
      append_after_word => "",
      gen_words => sub {
         my %args = @_;
         my $match = qr/^\Q$args{word}\E/i;
         my $at_sol = ( $args{wordpos} == 0 );

         my @matches;
         foreach my $group ( values %{ $obj->prop("completions") } ) {
            next if $group->prop("only_at_sol") and not $at_sol;
            my $suffix = $at_sol ? $group->prop("suffix_sol") : "";
            length $suffix or $suffix = " ";

            push @matches, map { "$_$suffix" }
                           grep { $_ =~ $match }
                           @{ $group->prop("items") };
         }

         return @matches;
      },
   );

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

use Tickit::Async 0.21;  # ->cancel_timer

use Tickit::Style -copy;

sub new
{
   my $class = shift;
   my %args = @_;

   my $tab = delete $args{tab};
   my $on_typing = delete $args{on_typing};

   if( $on_typing ) {
      my $on_enter = $args{on_enter};
      $args{on_enter} = sub {
         my ( $self ) = @_;
         $self->stopped_typing;
         $on_enter->( @_ );
      };
   }

   my $self = $class->SUPER::new( %args );

   $self->{tab} = $tab;
   $self->{on_typing} = $on_typing;

   return $self;
}

sub on_key
{
   my $self = shift;
   my ( $ev ) = @_;

   $self->{tab}->activated;

   my $ret = $self->SUPER::on_key( @_ );

   if( $ret && $self->{on_typing} and length $self->text ) {
      my $tickit = $self->window->tickit;

      if( $self->{typing_timer_id} ) {
         $tickit->cancel_timer( $self->{typing_timer_id} );
      }
      else {
         $self->started_typing;
      }

      $self->{typing_timer_id} = $tickit->timer( after => 5, sub { $self->stopped_typing });
   }

   return $ret;
}

sub started_typing
{
   my $self = shift;
   $self->{on_typing}->( 1 );
}

sub stopped_typing
{
   my $self = shift;
   $self->window->tickit->cancel_timer( $self->{typing_timer_id} ) if defined $self->{typing_timer_id};
   undef $self->{typing_timer_id};
   $self->{on_typing}->( 0 );
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
