# Copyrights 2010-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution XML-Compile-WSA.  Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package XML::Compile::SOAP::WSA;
use vars '$VERSION';
$VERSION = '0.95';

use base 'XML::Compile::SOAP::Extension';

use warnings;
use strict;

use Log::Report 'xml-compile-soap-wsa';

use XML::Compile::WSA::Util  qw/WSA10MODULE WSA09 WSA10 WSDL11WSAW/;
use XML::Compile::SOAP::Util qw/WSDL11/;
use XML::Compile::Util       qw/pack_type/;

use File::Spec              ();
use File::Basename          qw/dirname/;

my @common_hdr_elems = qw/To From Action ReplyTo FaultTo MessageID
  RelatesTo RetryAfter/;
my @wsa09_hdr_elems  = (@common_hdr_elems, qw/ReplyAfter/);
my @wsa10_hdr_elems  = (@common_hdr_elems, qw/ReferenceParameters/);

my %versions =
  ( '0.9' => { xsd => '20070619-wsa09.xsd', wsa => WSA09
             , hdr => \@wsa09_hdr_elems }
  , '1.0' => { xsd => '20080723-wsa10.xsd', wsa => WSA10
             , hdr => \@wsa10_hdr_elems }
  );

my $xsddir = File::Spec->catdir((dirname dirname __FILE__), 'WSA', 'xsd');


sub init($)
{   my ($self, $args) = @_;

    $self->SUPER::init($args);
    my $version = $args->{version}
        or error __x"explicit wsa_version required";
    trace "initializing wsa $version";

    $version = '1.0' if $version eq WSA10MODULE;
    $versions{$version}
        or error __x"unknown wsa version {v}, pick from {vs}"
             , v => $version, vs => [keys %versions];
    $self->{version} = $version;
    $self;
}

#-----------


sub version() {shift->{version}}
sub wsaNS()   {$versions{shift->{version}}{wsa}}

# This is not uglier than the WSA specification does: if you do not
# specify these attributes cleanly in the WSDL specs, then everyone
# needs hacks.
# Documented in XML::Compile::SOAP::Operation

sub XML::Compile::SOAP::Operation::wsaAction($)
{  my ($self, $dir) = @_;
   $dir eq 'INPUT' ? $self->{wsa}{action_input} : $self->{wsa}{action_output};
}

#-----------

sub _load_ns($$)
{   my ($self, $schema, $fn) = @_;
    $schema->importDefinitions(File::Spec->catfile($xsddir, $fn));
}

sub wsdl11Init($$)
{   my ($self, $wsdl, $args) = @_;
    my $def = $versions{$self->{version}};

    my $ns = $self->wsaNS;
    $wsdl->addPrefixes(wsa => $ns, wsaw => WSDL11WSAW);
    $wsdl->addKeyRewrite('PREFIXED(wsa,wsaw)');

    $wsdl->addCompileOptions('READERS'
      , anyElement   => 'TAKE_ALL'
      , anyAttribute => 'TAKE_ALL'
      );

    trace "loading wsa $self->{version}";
    $self->_load_ns($wsdl, $def->{xsd});
    $self->_load_ns($wsdl, '20060512-wsaw.xsd');

    my $wsa_action_ns = $self->version eq '0.9' ? $ns : WSDL11WSAW;
    $wsdl->addHook
      ( action => 'READER'
      , type   => pack_type(WSDL11, 'tParam')
      , after  => sub
          { my ($xml, $data, $path) = @_;
            $data->{wsa_action} = $xml->getAttributeNS($wsa_action_ns,'Action');
            $data;
          }
      );

    # [0.94] Many headers may contain attributes (which are usually not auto-
    # detected anyway), which will cause the field to be a HASH.  Older
    # versions of this module would always simply return the content, not a
    # HASH.  Let's not break those.
    $wsdl->addHook
      ( action => 'READER'
      , type   => 'wsa:AttributedURIType'
      , after  => sub
          { my ($xml, $data, $path) = @_;
            $data = $data->{_}
                if ref $data eq 'HASH' && keys %$data==1 && $data->{_};
            $data;
          }
      );

    # For unknown reason, the FaultDetail header is described everywhere
    # in the docs, but missing from the schema.
    $wsdl->importDefinitions( <<_FAULTDETAIL );
<schema xmlns="http://www.w3.org/2001/XMLSchema"
     xmlns:tns="$ns" targetNamespace="$ns"
     elementFormDefault="qualified"
     attributeFormDefault="unqualified">
  <element name="FaultDetail">
    <complexType>
      <sequence>
        <any minOccurs="0" maxOccurs="unbounded" />
      </sequence>
    </complexType>
  </element>
</schema>
_FAULTDETAIL

   $self;
}

sub soap11OperationInit($$)
{   my ($self, $op, $args) = @_;
    my $ns = $self->wsaNS;

    $op->{wsa}{action_input}  = $args->{input_def}{body}{wsa_action};
    $op->{wsa}{action_output} = $args->{output_def}{body}{wsa_action};

    trace "adding wsa header logic";
    my $def = $versions{$self->{version}};
    foreach my $hdr ( @{$def->{hdr}} )
    {   $op->addHeader(INPUT  => "wsa_$hdr" => "{$ns}$hdr");
        $op->addHeader(OUTPUT => "wsa_$hdr" => "{$ns}$hdr");
    }

    # soap11 specific
    $op->addHeader(OUTPUT => wsa_FaultDetail => "{$ns}FaultDetail");
}
*soap12OperationInit = \&soap11OperationInit;

sub soap11ClientWrapper($$$)
{   my ($self, $op, $call, $args) = @_;
    my $to     = ($op->endPoints)[0];
    my $action = $op->wsaAction('INPUT') || $op->soapAction;
#   my $outact = $op->wsaAction('OUTPUT');

    trace "added wsa in call $to".($action ? " for $action" : '');
    sub
    {   my $data = @_==1 ? shift : {@_};
        $data->{wsa_To}     ||= $to;
        $data->{wsa_Action} ||= $action;
        $call->($data);
        # should we check that the wsa_Action in the reply is correct?
    };
}
*soap12ClientWrapper = \&soap11ClientWrapper;

sub soap11HandlerWrapper($$$)
{   my ($self, $op, $cb, $args) = @_;
    my $outact = $op->wsaAction('OUTPUT');
    defined $outact
        or return $cb;

    sub
    {   my $data = $cb->(@_);
        $data->{wsa_Action} = $outact;
        $data;
    };
}
*soap12HandlerWrapper = \&soap11HandlerWrapper;


1;
