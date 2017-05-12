#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2010 -- leonerd@leonerd.org.uk

package Circle::FE::Gtk::Widget::Entry;

use strict;
use warnings;

use constant type => "Entry";

use Gtk2::Gdk::Keysyms;

sub build
{
   my $class = shift;
   my ( $obj, $tab ) = @_;

   my $tabobj = $tab->{object};

   my $widget = Gtk2::Entry->new();
   $obj->watch_property(
      property => "text",
      on_set => sub {
         my ( $text ) = @_;
         $text = "" unless defined $text;
         $widget->set_text( $text );
      },
      want_initial => 1,
   );

   $obj->watch_property(
      property => "history",
      on_updated => sub {}, # We ignore this, we just want a local cache
      want_initial => 1,
   );

   my $autoclear = $obj->prop("autoclear");

   my $history_index;

   $widget->signal_connect( activate =>
      sub {
         $obj->call_method(
            method => "enter",
            args => [ $widget->get_text ],

            on_result => sub {}, # IGNORE

            on_error => sub {
               my ( $message ) = @_;
               # TODO: write the error message somewhere
            },
         );
         $widget->set_text( "" ) if $autoclear;
         undef $history_index;
      },
   );

   $widget->signal_connect( key_press_event => 
      sub {
         my ( undef, $event ) = @_;

         if( $event->keyval == $Gtk2::Gdk::Keysyms{Up} ) {
            my $history = $obj->prop("history");
            if( !defined $history_index ) {
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
            $widget->set_position( -1 );

            return 1;
         }
         elsif( $event->keyval == $Gtk2::Gdk::Keysyms{Down} ) {
            my $history = $obj->prop("history");
            return 1 unless defined $history_index;
            if( $history_index < $#$history ) {
               $history_index++;
            }
            else {
               $widget->set_text( "" );
               undef $history_index;
               return 1;
            }

            my $line = $history->[$history_index];
            $widget->set_text( $line );
            $widget->set_position( -1 );

            return 1;
         }

         $tab->activated;
         return 0;
      }
   );

   $widget->modify_font( $tab->get_font );
   $widget->modify_base( normal => $tab->get_theme_colour( "bgcolor" ) );
   $widget->modify_text( normal => $tab->get_theme_colour( "textcolor" ) );

   if( $obj->prop("focussed") ) {
      $widget->signal_connect( realize => sub { $widget->grab_focus; } );
   }

   return $widget;
}

1;
