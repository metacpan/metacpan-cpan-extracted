# Copyrights 2007-2021 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution XML-Compile-SOAP.  Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package XML::Compile::SOAP11::Client;
use vars '$VERSION';
$VERSION = '3.27';

use base 'XML::Compile::SOAP11','XML::Compile::SOAP::Client';

use warnings;
use strict;

use Log::Report   'xml-compile-soap';

use XML::Compile::Util qw/unpack_type/;


1;
