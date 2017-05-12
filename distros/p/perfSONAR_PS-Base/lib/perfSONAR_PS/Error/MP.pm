use perfSONAR_PS::Error;

our $VERSION = 0.09;

=head1 NAME

perfSONAR_PS::Error::MP - A module that provides the measurement point 
exceptions framework for perfSONAR PS

=head1 DESCRIPTION

This module provides the measurement point exception objects

=head1 API

=cut

=head2 perfSONAR_PS::Error::MP

General exceptions for MP's; all following objects derive from this.

=cut
package perfSONAR_PS::Error::MP;
use base "perfSONAR_PS::Error";

=head2 perfSONAR_PS::Error::MP::Configuration

Configuration errors for the MP, such as invalid configuration, unparseable 
configuration etc.

=cut
package perfSONAR_PS::Error::MP::Configuration;
use base "perfSONAR_PS::Error::Common::Configuration";

=head2

Scheduling errors for the MP, such as the inability to schedule a test, test
schedule is not valid etc.

=cut
package perfSONAR_PS::Error::MP::Scheduler;
use base "perfSONAR_PS::Error::MP";

=head2 perfSONAR_PS::Error::MP::Agent

Errors from the agents performing the test, typically low level system problems
such as command not found, or unparseable output etc.

=cut
package perfSONAR_PS::Error::MP::Agent;
use base "perfSONAR_PS::Error::MP";


1;


=head1 SEE ALSO

L<Exporter>, L<Error::Simple>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.

=head1 VERSION

$Id$

=head1 AUTHOR

Yee-Ting Li <ytl@slac.stanford.edu>

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework along
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2004-2007, Internet2 and the University of Delaware

All rights reserved.

=cut
