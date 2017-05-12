#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2010 -- leonerd@leonerd.org.uk

package Circle::FE::Gtk::Widget::Label;

use strict;
use warnings;

use constant type => "Label";

sub build
{
   my $class = shift;
   my ( $obj, $tab ) = @_;

   my $widget = Gtk2::Label->new("");
   $obj->watch_property(
      property => "text",
      on_set   => sub { $widget->set_text( $_[0] ) },
      want_initial => 1,
   );

   return $widget;
}

1;
