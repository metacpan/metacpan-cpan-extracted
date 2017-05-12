use perfSONAR_PS::Error;

our $VERSION = 0.09;

=head1 NAME

perfSONAR_PS::Error::Common - A module that provides the exceptions framework 
that are common for perfSONAR PS

=head1 DESCRIPTION

This module provides the common exception objects.

=head1 API

=cut

=head2 perfSONAR_PS::Error::Common

Base exception object from which all other common exceptions inherit.

=cut
package perfSONAR_PS::Error::Common;
use base "perfSONAR_PS::Error";


=head2 perfSONAR_PS::Error::Transport

Transportation error, such as uncommunicative host, non-resolveable address etc.

=cut
package perfSONAR_PS::Error::Transport;
use base "perfSONAR_PS::Error";



# configuration and service startup

=head2 perfSONAR_PS::Error::Common::Configuration

Configuration error; such as not valid, cannot be found etc.

=cut
package perfSONAR_PS::Error::Common::Configuration;
use base "perfSONAR_PS::Error::Common";

=head2 perfSONAR_PS::Error::Common::NoLogger

No logger can be found

=cut
package perfSONAR_PS::Error::Common::NoLogger;
use base "perfSONAR_PS::Error::Common";

=head2 perfSONAR_PS::Error::Common::ActionNotSupported

Not sure - from EU

=cut
package perfSONAR_PS::Error::Common::ActionNotSupported;
use base "perfSONAR_PS::Error::Common";


#YTL: i'm guessing the manager maps to our daemon architecture here

=head2 perfSONAR_PS::Error::Common::Manager

Somethign went wrong with teh daemon architecture

=cut
package perfSONAR_PS::Error::Common::Manager;
use base "perfSONAR_PS::Error::Common";

=head2 perfSONAR_PS::Error::Common::Manager::NoConfiguration

The manager could not find an appropiate configuration file

=cut
package perfSONAR_PS::Error::Common::Manager::NoConfiguration;
use base "perfSONAR_PS::Error::Common::Manager";

=head2 perfSONAR_PS::Error::Common::Manager::CannotCreateComponent

the manager could not spawn off the relevant service

=cut
package perfSONAR_PS::Error::Common::Manager::CannotCreateComponent;
use base "perfSONAR_PS::Error::Common::Manager";


#YTL: storage related stuff; queryies etc. do we want MA's to subclass these errors? or should the mas
# just return these? ie do we need the granularity of each MA having their own error types considering
# we can have the specific message of the error as part of the error object 

=head2 perfSONAR_PS::Error::Common::Storage

Common storage exception object. All storage exceptions derive from this.

=cut
package perfSONAR_PS::Error::Common::Storage;
use base "perfSONAR_PS::Error::Common";

=head2 perfSONAR_PS::Error::Common::Storage::Query

The query is not valid, or the query is wrong; base object

=cut
package perfSONAR_PS::Error::Common::Storage::Query;
use base "perfSONAR_PS::Error::Common::Storage";

=head2 perfSONAR_PS::Error::Common::Storage::Query::IncompleteData

The data query is incomplete

=cut
package perfSONAR_PS::Error::Common::Storage::Query::IncompleteData;
use base "perfSONAR_PS::Error::Common::Storage";

=head2 perfSONAR_PS::Error::Common::Storage::Query::IncompleteMetaData

The metadata query is incomplete

=cut
package perfSONAR_PS::Error::Common::Storage::Query::IncompleteMetaData;
use base "perfSONAR_PS::Error::Common::Storage";

=head2 perfSONAR_PS::Error::Common::Storage::Query::InvalidTimestampType

The timestamp in the query is invalid

=cut
package perfSONAR_PS::Error::Common::Storage::Query::InvalidTimestampType;
use base "perfSONAR_PS::Error::Common::Storage";

=head2 perfSONAR_PS::Error::Common::Storage::Query::InvalidUpdateParamter

The update parameter is invalid

=cut
package perfSONAR_PS::Error::Common::Storage::Query::InvalidUpdateParamter;
use base "perfSONAR_PS::Error::Common::Storage";



=head2 perfSONAR_PS::Error::Common::Storage::Fetch

The fetch for the data failed.

=cut
package perfSONAR_PS::Error::Common::Storage::Fetch;
use base "perfSONAR_PS::Error::Common::Storage";

=head2 perfSONAR_PS::Error::Common::Storage::Open

Could not open the storage component (database etc) required.

=cut
package perfSONAR_PS::Error::Common::Storage::Open;
use base "perfSONAR_PS::Error::Common::Storage";

=head2 perfSONAR_PS::Error::Common::Storage::Update

An error with updating occured.

=cut
package perfSONAR_PS::Error::Common::Storage::Update;
use base "perfSONAR_PS::Error::Common::Storage";

=head2 perfSONAR_PS::Error::Common::Storage::Delete

Could not delete the appropriate item.

=cut
package perfSONAR_PS::Error::Common::Storage::Delete;
use base "perfSONAR_PS::Error::Common::Storage";

=head2 perfSONAR_PS::Error::Common::Storage::Close

An error with closing the storage component.

=cut
package perfSONAR_PS::Error::Common::Storage::Close;
use base "perfSONAR_PS::Error::Common::Storage";



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
