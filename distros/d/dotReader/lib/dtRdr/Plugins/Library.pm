package dtRdr::Plugins::Library;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use strict;
use warnings;

use Carp;

use base 'dtRdr::Plugins::Base';

use Module::Pluggable (
  search_path => ['dtRdr::Library'],
  only => qr/^dtRdr::Library::\w*$/,
  inner => 0,
  );


use constant {
  DEBUG => 1
};

=head1 NAME

dtRdr::Plugins::Library - handle library plugins

=head1 SYNOPSIS

=cut

=head2 init

  dtRdr::Plugins::Library->init(config => $config);

=cut

# see base




=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2006 Eric L. Wilhelm, All Rights Reserved.

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

# vi:ts=2:sw=2:et:sta
1;
