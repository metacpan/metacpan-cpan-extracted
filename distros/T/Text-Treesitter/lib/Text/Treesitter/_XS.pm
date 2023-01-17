#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

package Text::Treesitter::_XS 0.05;

use v5.14;
use warnings;

require XSLoader;
XSLoader::load( "Text::Treesitter", our $VERSION );

0x55AA;
