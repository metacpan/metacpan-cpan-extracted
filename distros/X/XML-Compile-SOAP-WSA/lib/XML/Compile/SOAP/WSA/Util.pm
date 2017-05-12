# Copyrights 2010-2012 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.00.
use warnings;
use strict;

package XML::Compile::SOAP::WSA::Util;
use vars '$VERSION';
$VERSION = '0.13';

use base 'Exporter';

my @wsa09  = qw/WSA09 WSA09FAULT WSA09ROLE_ANON/;
my @wsa10  = qw/WSA10 WSA10FAULT WSA10ADDR_ANON WSA10ADDR_NONE
                WSA10REL_REPLY WSA10REL_UNSPEC WSA10MODULE WSA10SOAP_FAULT/;
my @wsdl11 = qw/WSDL11WSAW/;
my @wsdl12 = ();  # don't know (yet)
my @soap11 = ();
my @soap12 = qw/SOAP12FEAT_DEST SOAP12FEAT_SE SOAP12FEAT_RE SOAP12FEAT_FE
                SOAP12FEAT_ACT SOAP12FEAT_ID SOAP12FEAT_REL SOAP12FEAT_REF/;

our @EXPORT_OK = (@wsa09, @wsa10, @wsdl11, @wsdl12, @soap11, @soap12);
our %EXPORT_TAGS =
  ( wsa09  => \@wsa09
  , wsa10  => \@wsa10
  , wsdl11 => \@wsdl11
  , wsdl12 => \@wsdl12
  , soap11 => \@soap11
  , soap12 => \@soap12
  );


use constant
  { WSA09           => 'http://schemas.xmlsoap.org/ws/2004/08/addressing'
  , WSA10           => 'http://www.w3.org/2005/08/addressing'
  };

use constant
  { WSA09FAULT      => WSA09.'/fault'
  , WSA09ROLE_ANON  => WSA09.'/role/anonymous'
  };


use constant
  { WSA10FAULT      => WSA10.'/fault'
  , WSA10SOAP_FAULT => WSA10.'/soap/fault'
  , WSA10ADDR_ANON  => WSA10.'/anonymous'
  , WSA10ADDR_NONE  => WSA10.'/none'
  , WSA10REL_REPLY  => WSA10.'/reply'
  , WSA10REL_UNSPEC => WSA10.'/unspecified'
  , WSA10MODULE     => WSA10.'/module'
  };


use constant
  { WSDL11WSAW      => 'http://www.w3.org/2006/05/addressing/wsdl'
  };


use constant
  { SOAP12FEATURE   => 'http://www.w3.org/2005/08/addressing/feature'
  };

use constant
  { SOAP12FEAT_DEST => SOAP12FEATURE.'/Destination'
  , SOAP12FEAT_SE   => SOAP12FEATURE.'/SourceEndpoint'
  , SOAP12FEAT_RE   => SOAP12FEATURE.'/ReplyEndpoint'
  , SOAP12FEAT_FE   => SOAP12FEATURE.'/FaultEndpoint'
  , SOAP12FEAT_ACT  => SOAP12FEATURE.'/Action'
  , SOAP12FEAT_ID   => SOAP12FEATURE.'/MessageID'
  , SOAP12FEAT_REL  => SOAP12FEATURE.'/Relationship'
  , SOAP12FEAT_REF  => SOAP12FEATURE.'/ReferenceParameters'
  };

1;

