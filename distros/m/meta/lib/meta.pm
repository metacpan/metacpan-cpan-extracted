#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

package meta 0.001;

use v5.14;
use warnings;

=head1 NAME

C<meta> - meta-programming API (PLACEHOLDER)

=head1 DESCRIPTION

This is a placeholder module for what will hopefully become a new dual-life
core module, which is currently in development.

The module description may eventually be something like:

This package provides an API for metaprogramming; that is, allowing code to
inspect or manipulate parts of its own program structure.  Parts of the perl
interpreter itself can be accessed by means of "meta"-objects provided by this
package.  Methods on these objects allow inspection of details, as well as
creating new items or removing existing ones.

The intention of this API is to provide a nicer replacement for existing
tricks such as C<no strict 'refs'> and using globrefs, and also to be a more
consistent place to add new abilities, such as more APIs for inspection and
alteration of internal structures, metaprogramming around the new C<'class'>
feature, and other such uses.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
