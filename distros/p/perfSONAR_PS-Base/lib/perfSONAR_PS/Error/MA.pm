use perfSONAR_PS::Error;
use perfSONAR_PS::Error::Common;

our $VERSION = 0.09;

=head1 NAME

perfSONAR_PS::Error::MA - A module that provides the measurement archive 
exceptions framework for perfSONAR PS

=head1 DESCRIPTION

This module provides the measurement archive exception objects.

=head1 API

=cut


package perfSONAR_PS::Error::MA;
use base "perfSONAR_PS::Error";


package perfSONAR_PS::Error::MA::Configuration;
use base "perfSONAR_PS::Error::Common::Configuration";



=cut

# not sure about these as they are provided under Common

package perfSONAR_PS::Error::MA::Query;
use base "perfSONAR_PS::Error::Common::Storage::Query";

package perfSONAR_PS::Error::MA::Query::IncompleteData;
use base "perfSONAR_PS::Error::MA::Query";

package perfSONAR_PS::Error::MA::Query::IncompleteMetaData;
use base "perfSONAR_PS::Error::MA::Query";

package perfSONAR_PS::Error::MA::Query::InvalidKnowledgeLevel;
use base "perfSONAR_PS::Error::MA::Query";

package perfSONAR_PS::Error::MA::Query::InvalidTimestampType;
use base "perfSONAR_PS::Error::MA::Query";

package perfSONAR_PS::Error::MA::Query::InvalidUpdateParamter;
use base "perfSONAR_PS::Error::MA::Query";


package perfSONAR_PS::Error::MA::Select;
use base "perfSONAR_PS::Error::MA";

package perfSONAR_PS::Error::MA::Status;
use base "perfSONAR_PS::Error::MA";

package perfSONAR_PS::Error::MA::Status::NoLinkId;
use base "perfSONAR_PS::Error::MA::Status";

package perfSONAR_PS::Error::MA::Storage;
use base "perfSONAR_PS::Error::MA";

package perfSONAR_PS::Error::MA::StorageResult;
use base "perfSONAR_PS::Error::MA";

package perfSONAR_PS::Error::MA::Storage::Result;
use base "perfSONAR_PS::Error::MA::Storage";


package perfSONAR_PS::Error::MA::Structure;
use base "perfSONAR_PS::Error::MA";


package perfSONAR_PS::Error::MA::Transport;
use base "perfSONAR_PS::Error::MA";
=cut

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



