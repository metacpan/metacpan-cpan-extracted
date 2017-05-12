# Copyrights 2011-2017 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package XML::Compile::SOAP::WSS;
use vars '$VERSION';
$VERSION = '1.14';

use base 'XML::Compile::SOAP::Extension';

use Log::Report 'xml-compile-wss';

use XML::Compile::WSS::Util  qw/:wss11 :utp11/;
use XML::Compile::WSS        ();
use XML::Compile::SOAP::Util qw/SOAP11ENV/;

use Scalar::Util             qw/weaken/;


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);
    $self->{XCSW_wss} = [];

    my $schema = $self->{XCSW_schema} = $args->{schema};
    weaken $self->{XCSW_schema};

    # [1.0] to support backwards compat
    XML::Compile::WSS->loadSchemas($schema, '1.1') if $schema;
    $self;
}

sub wsdl11Init($$)
{   my ($self, $wsdl, $args) = @_;
    $self->SUPER::wsdl11Init($wsdl, $args);

    $self->{XCSW_schema} = $wsdl;
    weaken $self->{XCSW_schema};

    XML::Compile::WSS->loadSchemas($wsdl, '1.1');
    $wsdl->addPrefixes('SOAP-ENV' => SOAP11ENV);

    $self;
}

sub soap11OperationInit($$)
{   my ($self, $op, $args) = @_;

    my $schema = $self->schema
        or error __x"WSS not connected to the WSDL: WSS needs to be instantiated
before the WSDL because it influences its interpretation";

    # this is not a nice hack for apps where multiple ::WSDL or ::Schema
    # objects are active https://rt.cpan.org/Ticket/Display.html?id=99735
    $schema eq $op->schemas or return;

    trace "adding wss header logic";  # get full type from any schema
    my $sec = $schema->findName('wsse:Security');
    $op->addHeader(INPUT  => "wsse_Security" => $sec, mustUnderstand => 1);
    $op->addHeader(OUTPUT => "wsse_Security" => $sec, mustUnderstand => 1);
}
*soap12OperationInit = \&soap11OperationInit;

sub soap11ClientWrapper($$$)
{   my ($self, $op, $call, $args) = @_;

    $self->schema eq $op->schemas or return;

    sub {
        my $data = @_==1 ? shift : {@_};
        my $sec  = $data->{wsse_Security};

        # Support pre-1.0 interface
        return $call->($data)
            if ref $sec eq 'HASH';

        # select plugins
        my $wss  = $sec || $self->{XCSW_wss};
        my @wss  = ref $wss eq 'ARRAY' ? @$wss : $wss;

        # Adding WSS headers to $secw
        my $secw = $data->{wsse_Security} = {};
        my $doc  = $data->{_doc} ||= XML::LibXML::Document->new('1.0','UTF-8');
        $_->create($doc, $secw) for @wss;
 
        # The real work: SOAP message formatting and exchange
        my ($answer, $trace) = $call->($data);

        if(defined $answer)
        {   my $secr = $answer->{wsse_Security} ||= {};
            $_->check($secr) for @wss;
        }
 
        wantarray ? ($answer, $trace) : $answer;
    };
}
*soap12ClientWrapper = \&soap11ClientWrapper;

#---------------------------

sub schema()   { shift->{XCSW_schema} }
sub features() { @{shift->{XCSW_wss}} }

sub addFeature($)
{   my ($self, $n) = @_;
    my $schema = $n->schema
        or error __x"no schema yet. Instantiate ::WSS before ::WSDL";

    push @{$self->{XCSW_wss}}, $n;
    $n;
}

#---------------------------

sub _start($$)
{   my ($self, $plugin, $args) = @_;

    eval "require $plugin";
    panic $@ if $@;

    my $schema = $args->{schema} ||= $self->schema
        or error __x"instantiate {pkg} before the wsdl, plugins after"
             , pkg => __PACKAGE__;

    $self->addFeature($plugin->new($args));
}


sub basicAuth(%)
{   my ($self, %args) = @_;
    $self->_start('XML::Compile::WSS::BasicAuth', \%args);
}


sub timestamp(%)
{   my ($self, %args) = @_;
    $self->_start('XML::Compile::WSS::Timestamp', \%args);
}


sub signature(%)
{   my ($self, %args) = @_;
    my $schema = $args{schema} || $self->schema;

    my $has12  = defined $schema->prefix('env12');
    $args{sign_types} ||= ['SOAP-ENV:Body', ($has12 ? 'env12:Body' : ())];
    $args{sign_put}   ||= 'wsse:SecurityHeaderType';
    $args{sign_when}  ||= ['SOAP-ENV:Envelope', ($has12 ? 'env12:Envelope':())];

    my $sig    = $self->_start('XML::Compile::WSS::Signature', \%args);
    $sig;
}

#--------------------------------------
# [1.0] Expired interface
sub wsseBasicAuth($$$@)
{   my ($self, $username, $password, $pwtype, %args) = @_;
    # use XML::Compile::WSS::BasicAuth!!!  This method will be removed!

    eval "require XML::Compile::WSS::BasicAuth";
    panic $@ if $@;

    my $auth = XML::Compile::WSS::BasicAuth->new
      ( username  => $username
      , password  => $password
      , pwformat  => $pwtype || UTP11_PTEXT
      , %args
      , schema    => $self->schema
      );

    my $doc  = XML::LibXML::Document->new('1.0', 'UTF-8');
    $auth->create($doc, {});
}

# [1.0] Expired interface
sub wsseTimestamp($$$@)
{   my ($self, $created, $expires, %args) = @_;
    # use XML::Compile::WSS::Timestamp!!!  This method will be removed!

    eval "require XML::Compile::WSS::Timestamp";
    panic $@ if $@;

    my $ts = XML::Compile::WSS::Timestamp->new
      ( created => $created 
      , expires => $expires
      , %args
      , schema  => $self->schema
      );

    my $doc  = XML::LibXML::Document->new('1.0', 'UTF-8');
    $ts->create($doc, {});
}

1;
