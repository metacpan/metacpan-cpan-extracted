#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2010 -- leonerd@leonerd.org.uk

package Circle::FE::Gtk::Widget::Label;

use strict;
use warnings;

use constant type => "Label";
use Variable::Disposition qw( retain_future );

sub build
{
   my $class = shift;
   my ( $obj, $tab ) = @_;

   my $widget = Gtk2::Label->new("");
   retain_future $obj->watch_property_with_initial(
      "text",
      on_set => sub { $widget->set_text( $_[0] ) },
   );

   return $widget;
}

1;
