# Copyrights 2016 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package XML::Compile::Licensed;
use vars '$VERSION';
$VERSION = '0.01';


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
