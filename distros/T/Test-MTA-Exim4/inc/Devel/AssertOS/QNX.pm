# $Id: QNX.pm,v 1.2 2008/10/27 20:31:21 drhyde Exp $

package #
Devel::AssertOS::QNX;

use Devel::CheckOS;

$VERSION = '1.2';

sub matches { return qw(QNX::v4 QNX::Neutrino); }
sub os_is { Devel::CheckOS::os_is(matches()); }
sub expn {
join("\n", 
"All versions of QNX match this, as well as (possibly) a more specific",
"match"
)
}
Devel::CheckOS::die_unsupported() unless(os_is());

=head1 COPYRIGHT and LICENCE

Copyright 2007 - 2008 David Cantrell

This software is free-as-in-speech software, and may be used, distributed, and modified under the terms of either the GNU General Public Licence version 2 or the Artistic Licence. It's up to you which one you use. The full text of the licences can be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=cut

1;
