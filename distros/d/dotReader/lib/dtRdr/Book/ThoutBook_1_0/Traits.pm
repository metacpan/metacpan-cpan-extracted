package dtRdr::Book::ThoutBook_1_0::Traits;
$VERSION = eval{require version}?version::qv($_):$_ for(0.0.1);

use warnings;
use strict;

BEGIN { # naive traits implementation
use Exporter;
*{import} = \&Exporter::import;
}

our @EXPORT_OK = qw(
  _boolify
);

=head1 NAME

dtRdr::Book::ThoutBook_1_0::Traits - shared methods

=head1 SYNOPSIS

This module provides some shared code.

=head2 _boolify

Transform true/false/undef into a boolean -- defaults to true on undef.

  _boolify('true|false|');

=cut

sub _boolify {
  my ($val) = @_;
  return((($val || 'true') eq 'true') ? 1 : 0);
} # end subroutine _boolify definition
########################################################################

=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

=head1 COPYRIGHT

Copyright (C) 2006 Eric L. Wilhelm and OSoft, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

The dotReader(TM) is OSI Certified Open Source Software licensed under
the GNU General Public License (GPL) Version 2, June 1991. Non-encrypted
and encrypted packages are usable in connection with the dotReader(TM).
The ability to create, edit, or otherwise modify content of such
encrypted packages is self-contained within the packages, and NOT
provided by the dotReader(TM), and is addressed in a separate commercial
license.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut

# vim:sts=2:sw=2:et:sta
1;
