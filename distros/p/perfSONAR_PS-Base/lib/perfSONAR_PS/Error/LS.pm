use perfSONAR_PS::Error;

our $VERSION = 0.09;

=head1 NAME

perfSONAR_PS::Error::LS - A module that provides the Lookup Service exceptions
framework for perfSONAR PS

=head1 DESCRIPTION

This module provides the Lookup Service exception objects.

=head1 API

=cut


package perfSONAR_PS::Error::LS;
use base "perfSONAR_PS::Error";


# general

package perfSONAR_PS::Error::LS::NoStorage;
use base "perfSONAR_PS::Error::LS";


# errors for registration (storage into LS)

package perfSONAR_PS::Error::LS::ActionNotSupported;
use base "perfSONAR_PS::Error::LS";

package perfSONAR_PS::Error::LS::NoAccessPoint;
use base "perfSONAR_PS::Error::LS";

package perfSONAR_PS::Error::LS::NoMetadata;
use base "perfSONAR_PS::Error::LS";

package perfSONAR_PS::Error::LS::NoEventType;
use base "perfSONAR_PS::Error::LS";

package perfSONAR_PS::Error::LS::EventTypeNotSupported;
use base "perfSONAR_PS::Error::LS";

package perfSONAR_PS::Error::LS::NoKey;
use base "perfSONAR_PS::Error::LS";


# not sure about this one; it was from the EU project

package perfSONAR_PS::Error::LS::NoScheduler;
use base "perfSONAR_PS::Error::LS";



## queries

package perfSONAR_PS::Error::LS::QueryTypeNotSupported;
use base "perfSONAR_PS::Error::LS";

package perfSONAR_PS::Error::LS::KeyNotFound;
use base "perfSONAR_PS::Error::LS";

package perfSONAR_PS::Error::LS::NoQueryType;
use base "perfSONAR_PS::Error::LS";

package perfSONAR_PS::Error::LS::NoDataTrigger;
use base "perfSONAR_PS::Error::LS";


# inserts/updates

package perfSONAR_PS::Error::LS::CannotReplaceData;
use base "perfSONAR_PS::Error::LS";

package perfSONAR_PS::Error::LS::NoStorageContent;
use base "perfSONAR_PS::Error::LS";

package perfSONAR_PS::Error::LS::Update;
use base "perfSONAR_PS::Error::LS";

package perfSONAR_PS::Error::LS::Update::KeyNotFound;
use base "perfSONAR_PS::Error::LS::Update";


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



