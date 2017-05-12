#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2010 -- leonerd@leonerd.org.uk

package Circle::FE::Gtk::Widget::Box;

use strict;
use warnings;

use constant type => "Box";

use Glib qw( TRUE FALSE );

sub build
{
   my $class = shift;
   my ( $obj, $tab ) = @_;

   my $orientation = $obj->prop("orientation");
   my $widget;
   if( $orientation eq "vertical" ) {
      $widget = Gtk2::VBox->new();
   }
   elsif( $orientation eq "horizontal" ) {
      $widget = Gtk2::HBox->new();
   }
   else {
      die "Unrecognised orientation '$orientation'";
   }

   my $do_end;

   foreach my $c ( @{ $obj->prop("children") } ) {
      if( $c->{child} ) {
         my $childwidget = $tab->build_widget( $c->{child} );
         $widget->pack_start( $childwidget, $c->{expand}, $c->{expand}, 0 );
      }
      else {
         # Ah.. Here's a spacer.
         $do_end = 1;
         last;
      }
   }

   if( $do_end ) {
      foreach my $c ( reverse @{ $obj->prop("children") } ) {
         last unless $c->{child};
         my $childwidget = $tab->build_widget( $c->{child} );
         $widget->pack_end( $childwidget, $c->{expand}, $c->{expand}, 0 );
      }
   }

   return $widget;
}

1;
