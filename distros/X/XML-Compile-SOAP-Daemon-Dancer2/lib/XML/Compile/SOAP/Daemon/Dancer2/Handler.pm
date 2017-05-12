package XML::Compile::SOAP::Daemon::Dancer2::Handler;
use warnings;
use strict;
use vars '$VERSION';
$VERSION = '0.1';

use parent 'XML::Compile::SOAP::Daemon';

use Log::Report 'xml-compile-soap-daemon';
use Encode;


use constant
  { RC_OK                 => 200
  , RC_METHOD_NOT_ALLOWED => 405
  , RC_NOT_ACCEPTABLE     => 406
  , RC_SERVER_ERROR       => 500
  };

#--------------------


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);
    $self->_init($args);
    $self;
}

#------------------------------

sub _init($)
{   my ($self, $args) = @_;
    $self->{preprocess}  = $args->{preprocess};
    $self->{postprocess} = $args->{postprocess};
    $self;
}


my $parser        = XML::LibXML->new;
sub handle($)
{   my ($self, $dsl) = @_;

    notice __x"WSA module loaded, but not used"
        if XML::Compile::SOAP::WSA->can('new') && !keys %{$self->{wsa_input}};
    $self->{wsa_input_rev}  = +{ reverse %{$self->{wsa_input}} };

    #return $self->sendWsdl($req)
        #if $req->method eq 'GET' && uc($req->uri->query || '') eq 'WSDL';

    my $method = $dsl->app->request->method;
    my $ct     = $dsl->app->request->content_type || 'text/plain';
    $ct =~ s/\;\s.*//;

    my ($rc, $msg, $err, $content, $mime);
    if($method ne 'POST' && $method ne 'M-POST')
    {   ($rc, $msg) = (RC_METHOD_NOT_ALLOWED, 'only POST or M-POST');
        $err = 'attempt to connect via GET';
    }
    elsif($ct !~ m/\bxml\b/)
    {   ($rc, $msg) = (RC_NOT_ACCEPTABLE, 'required is XML');
        $err = 'content-type seems to be '.$ct.', must be some XML';
    }
    else
    {   my $charset = $dsl->app->request->headers->content_type_charset || 'ascii';
        my $xmlin   = try { $parser->parse_string( decode( $charset, $dsl->app->request->content ) ); };

        if( $@ ) {
            ($rc, $msg, $err) = $self->faultInvalidXML($@->died);
        } else {
            my $version = undef;
            $xmlin= $xmlin->documentElement
                if $xmlin->isa('XML::LibXML::Document');

            my $local  = $xmlin->localName;

            if( $local eq 'Envelope' ) {
                my $envns  = $xmlin->namespaceURI || '';
                my $proto  = XML::Compile::SOAP->fromEnvelope($envns);
                if( $proto ) {
                    $version = $proto->version;
                }
            }
            my $action  = $dsl->app->request->header('SOAPAction') || $dsl->app->request->header('Action') || $dsl->app->request->header('action') || '';
            $action     =~ s/["'\s]//g;   # sometimes illegal quoting and blanks "
            ($rc, $msg, my $xmlout) = $self->process($xmlin, $dsl, $action);

            if(UNIVERSAL::isa($xmlout, 'XML::LibXML::Document'))
            {
                $content = $xmlout->toString($rc == RC_OK ? 0 : 1);
                if( $version eq "SOAP11" ) {
                    $mime  = 'text/xml; charset="utf-8"';
                } else {
                    $mime  = "application/soap+xml; charset=utf-8";
                }
            }
            else
            {
                $err   = $xmlout;
            }
        }
    }

    if( $err ) {
        $content = $err;#            $bytes = "[$rc] $err\n";
        $mime  = 'text/plain';
    }
    $dsl->status( $rc );
    $dsl->content_type( $mime );
    $dsl->header( Warning => "199 $msg" ) if length( $msg );
    #$dsl->content_length(length $bytes);
    return $content;
}

1;
