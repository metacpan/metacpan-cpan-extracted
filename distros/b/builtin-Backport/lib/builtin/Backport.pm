#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

package builtin::Backport 0.02;

use v5.18;
use warnings;

=head1 NAME

C<builtin::Backport> - provide backported C<builtin> functions for earlier Perl versions

=head1 DESCRIPTION

Perl version 5.36 added many functions in a module called C<builtin>; these
may be further expanded in later perl versions. Many of the functions provided
in this space, however, can be implemented just fine on earlier Perl versions.

This distribution provides a modified F<builtin.pm> file which includes most
of the missing functions for earlier versions of Perl. Once installed, code
can simply C<use builtin ...> as would work on Perl 5.36 onwards, and for the
most part would work identically.

Some functions cannot be supported on older versions; where necessary this is
pointed out in the modified documentation in the module.

Because C<builtin> itself uses lexical exporting to provide its functions,
they can only be provided on Perl version 5.18 onwards, when lexical subs were
implemented.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
