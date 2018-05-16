# Copyrights 2009-2018 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution XML-Compile-SOAP12.  Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

# may be incomplete.... please add
package XML::Compile::SOAP12::Util;
use vars '$VERSION';
$VERSION = '3.06';

use base 'Exporter';

use warnings;
use strict;

my @soap12  = qw/SOAP12ENV SOAP12ENC SOAP12RPC
 SOAP12BIND SOAP12MEP SOAP12FEATURES/;

my @roles   = qw/SOAP12NONE SOAP12NEXT SOAP12ULTIMATE/;

my @context = qw/SOAP12CONTEXT SOAP12CTXPATTERN SOAP12CTXFAILURE
  SOAP12CTXROLE SOAP12CTXSTATE/;

my @features= qw/SOAP12WEBMETHOD SOAP12METHODPROP SOAP12ACTION
  SOAP12ACTIONPROP/;

my @mep     = qw/SOAP12MEP SOAP12REQRESP SOAP12RESP
  SOAP12MEPOUT SOAP12MEPIN SOAP12MEPDEST SOAP12MEPSEND/;

our @EXPORT = (@soap12, @roles, @context, @features, @mep);
our %EXPORT_TAGS =
  ( soap12   => \@soap12
  , roles    => \@roles
  , context  => \@context
  , features => \@features
  , mep      => \@mep
  );


use constant SOAP12 => 'http://www.w3.org/2003/05/';

use constant
 { SOAP12ENV      => SOAP12.'soap-envelope'
 , SOAP12ENC      => SOAP12.'soap-encoding'
 , SOAP12RPC      => SOAP12.'soap-rpc'
 , SOAP12BIND     => SOAP12.'soap/bindingFramework'
 , SOAP12MEP      => SOAP12.'soap/mep'
 , SOAP12FEATURES => SOAP12.'soap/features'
 };


use constant
 { SOAP12NONE     => SOAP12ENV.'/role/none'
 , SOAP12NEXT     => SOAP12ENV.'/role/next'
 , SOAP12ULTIMATE => SOAP12ENV.'/role/ultimateReceiver'
 };


use constant
 { SOAP12CONTEXT  => SOAP12BIND.'/ExchangeContext'
 };


use constant
 { SOAP12CTXPATTERN => SOAP12CONTEXT.'/ExchangePatternName'
 , SOAP12CTXFAILURE => SOAP12CONTEXT.'/FailureReason'
 , SOAP12CTXROLE    => SOAP12CONTEXT.'/Role'
 , SOAP12CTXSTATE   => SOAP12CONTEXT.'/State'
 };


use constant
 { SOAP12WEBMETHOD  => SOAP12FEATURES.'/web-method/'
 , SOAP12ACTION     => SOAP12FEATURES.'/action/'
 };

use constant
 { SOAP12METHODPROP => SOAP12WEBMETHOD.'Method'
 , SOAP12ACTIONPROP => SOAP12ACTION.'Action'
 };


use constant
 { SOAP12REQRESP    => SOAP12MEP.'/request-response/'
 , SOAP12RESP       => SOAP12MEP.'/soap-response/'
 , SOAP12MEPOUT     => SOAP12MEP.'/OutboundMessage'
 , SOAP12MEPIN      => SOAP12MEP.'/IntboundMessage'
 , SOAP12MEPDEST    => SOAP12MEP.'/ImmediateDestination'
 , SOAP12MEPSEND    => SOAP12MEP.'/ImmediateSender'
 };


1;
