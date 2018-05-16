# Copyrights 2007-2018 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution XML-Compile-SOAP-Daemon.  Meta-POD
# processed with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package XML::Compile::SOAP::HTTPDaemon;
use vars '$VERSION';
$VERSION = '3.14';


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
