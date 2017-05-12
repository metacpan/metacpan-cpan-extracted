#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2011-2015 -- leonerd@leonerd.org.uk

package Circle::FE::Term::Widget::Label;

use strict;
use warnings;

use constant type => "Label";

use Tickit::Widget::Static;

sub build
{
   my $class = shift;
   my ( $obj, $tab ) = @_;

   my $widget = Tickit::Widget::Static->new(
      classes => $obj->prop( "classes" ),
      text => "",
   );

   $tab->adopt_future(
      $obj->watch_property_with_initial(
         "text",
         on_set => sub { $widget->set_text( $_[0] ) },
      )
   );

   return $widget;
}

Tickit::Style->load_style( <<'EOF' );
Static.ident {
  bg: "blue";
}

Static.transient {
  fg: "yellow";
  b: 1;
}

EOF

0x55AA;
