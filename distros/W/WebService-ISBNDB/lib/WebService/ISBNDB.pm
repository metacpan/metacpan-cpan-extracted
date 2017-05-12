###############################################################################
#
# This file copyright (c) 2006-2008 by Randy J. Ray, all rights reserved
#
# See "LICENSE" in the documentation for licensing and redistribution terms.
#
###############################################################################
#
#   $Id: ISBNDB.pm 50 2008-04-06 10:53:33Z  $
#
#   Description:    Empty, placeholder module for version-test capability.
#
#   Functions:      None
#
###############################################################################

package WebService::ISBNDB;

use 5.006;
use strict;
use warnings;
use vars qw($VERSION);

$VERSION = "0.34";

1;

=pod

=head1 NAME

WebService::ISBNDB - A Perl extension to access isbndb.com

=head1 DESCRIPTION

This module provides no routines or methods. Its purpose is to provide a
testable version for other modules that depend on this distribution.

=head1 SEE ALSO

L<WebService::ISBNDB::API>, L<WebService::ISBNDB::API::Authors>,
L<WebService::ISBNDB::Books>, L<WebService::ISBNDB::API::Categories>,
L<WebService::ISBNDB::API::Publishers>, L<WebService::ISBNDB::API::Subjects>,
L<WebService::ISBNDB::Agent>, L<WebService::ISBNDB::Agent::REST>,
L<WebService::ISBNDB::Iterator>

=head1 AUTHOR

Randy J. Ray E<lt>rjray@blackperl.comE<gt>

=head1 LICENSE

This module and the code within are
released under the terms of the Artistic License 2.0
(http://www.opensource.org/licenses/artistic-license-2.0.php). This
code may be redistributed under either the Artistic License or the GNU
Lesser General Public License (LGPL) version 2.1
(http://www.opensource.org/licenses/lgpl-license.php).

=cut
