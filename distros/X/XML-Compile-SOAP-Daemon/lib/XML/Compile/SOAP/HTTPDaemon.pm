# Copyrights 2007-2017 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.

package XML::Compile::SOAP::HTTPDaemon;
use vars '$VERSION';
$VERSION = '3.13';


use XML::Compile::SOAP::Daemon::NetServer;

# For more than one reason, this module has changed name. The most
# important being that HTTPDaemon seems to relate to HTTP::Daemon
# from LWP... which is not true!

BEGIN
{
    print STDERR <<'_ERR';

*
*** Since v3.00, XML::Compile::SOAP::HTTPDaemon renamed to
*** XML::Compile::SOAP::Daemon::NetServer.  Please change
*** your code (besides this message it should still work)
*

_ERR
    sleep 5
}

sub new(@)
{   my $class = shift;
    XML::Compile::SOAP::Daemon::NetServer->new(@_);
}

1;
