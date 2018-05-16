# Copyrights 2016-2018 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution XML-Compile-Licensed.  Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself

package XML::Compile::Licensed;
use vars '$VERSION';
$VERSION = '0.02';


use warnings;
use strict;

use File::Spec     ();
use File::Basename qw/dirname/;


our %soap_servers =
  ( BEA =>          # Oracle's BEA
      { xsddir => 'bea'
      , xsds   => [ qw(bea_wli_sb_context.xsd bea_wli_sb_context-fix.xsd) ]
      }
  , SharePoint =>   # MicroSoft's SharePoint
      { xsddir => 'sharepoint'
      , xsds   => [ qw(sharepoint-soap.xsd sharepoint-serial.xsd) ]
      }
  );

sub soapServer($)
{   my ($class, $type) = @_;
    my $config = $soap_servers{$type} or return ();

    my $up     = dirname __FILE__;
    my $xsddir = File::Spec->catdir($up, 'SOAP', 'xsd', $config->{xsddir});
    ($xsddir, $config);
}

1;
