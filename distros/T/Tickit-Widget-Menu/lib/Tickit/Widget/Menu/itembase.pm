#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2020 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.33;

package Tickit::Widget::Menu::itembase 0.12;
role Tickit::Widget::Menu::itembase;

has $_name;

BUILD ( %args )
{
   $_name = $args{name};
}

method name () { $_name }

method render_label ( $rb, $cols, $menu )
{
   $rb->text( $_name );
}

0x55AA;
