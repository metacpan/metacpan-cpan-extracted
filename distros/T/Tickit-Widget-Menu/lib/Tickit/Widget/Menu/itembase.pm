#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2022 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.73 ':experimental(init_expr)';

package Tickit::Widget::Menu::itembase 0.16;
role Tickit::Widget::Menu::itembase;

field $_name :param :reader = undef;

method render_label ( $rb, $cols, $menu )
{
   $rb->text( $_name );
}

0x55AA;
