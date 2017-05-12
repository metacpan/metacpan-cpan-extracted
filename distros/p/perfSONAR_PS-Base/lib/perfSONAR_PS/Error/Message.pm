use perfSONAR_PS::Error;

our $VERSION = 0.09;

=head1 NAME

perfSONAR_PS::Error::Message - A module that provides the message exceptions 
framework for perfSONAR PS

=head1 DESCRIPTION

This module provides the message exception objects.

=head1 API

=cut

=head2 perfSONAR_PS::Error::Message

Base exception class from which all following exception objects derive.

=cut
package perfSONAR_PS::Error::Message;
use base "perfSONAR_PS::Error";

=head2 perfSONAR_PS::Error::Message::InvalidXML

The XML is invalid, either it is not well formed, or has other issues.

=cut
package perfSONAR_PS::Error::Message::InvalidXML;
use base "perfSONAR_PS::Error::Message";


=head2 perfSONAR_PS::Error::Message

Chaining errors, such as invalid chaining defined, or chaining could not be resolved.

=cut
package perfSONAR_PS::Error::Message::Chaining;
use base "perfSONAR_PS::Error::Message";


=head2 perfSONAR_PS::Error::Message::NoMessageType

No message type was provided.

=cut
package perfSONAR_PS::Error::Message::NoMessageType;
use base "perfSONAR_PS::Error::Message";

=head2 perfSONAR_PS::Error::Message::InvalidMessageType

The message type provided is invalid, it is not supported.

=cut
package perfSONAR_PS::Error::Message::InvalidMessageType;
use base "perfSONAR_PS::Error::Message";

=head2 perfSONAR_PS::Error::Message::NoEventType

No Event Type was provided.

=cut
package perfSONAR_PS::Error::Message::NoEventType;
use base "perfSONAR_PS::Error::Message";

=head2 perfSONAR_PS::Error::Message::InvalidEventType

The event type is not supported or is invalid.

=cut
package perfSONAR_PS::Error::Message::InvalidEventType;
use base "perfSONAR_PS::Error::Message";


=head2 perfSONAR_PS::Error::Message::InvalidKey

The provide key is invalid or cannot be resolved.

=cut
package perfSONAR_PS::Error::Message::InvalidKey;
use base "perfSONAR_PS::Error::Message";

=head2 perfSONAR_PS::Error::Message::InvalidSubject

The provided subject was invalid.

=cut
package perfSONAR_PS::Error::Message::InvalidSubject;
use base "perfSONAR_PS::Error::Message";

=head2 perfSONAR_PS::Error::Message::NoMetaDataPair

The metadata does not resolve to a data element.

=cut
package perfSONAR_PS::Error::Message::NoMetadataDataPair;
use base "perfSONAR_PS::Error::Message";




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


