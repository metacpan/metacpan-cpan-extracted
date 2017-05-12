# Copyrights 2007-2016 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package XML::Compile::SOAP::Daemon::PSGI;
use vars '$VERSION';
$VERSION = '3.12';

use parent 'XML::Compile::SOAP::Daemon', 'Plack::Component';

use Log::Report 'xml-compile-soap-daemon';
use Encode;
use Plack::Request;
use Plack::Response;


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

sub run(@)
{   my ($self, $args) = @_;
    $self->_init($args);
    $self->to_app;
}

sub _init($)
{   my ($self, $args) = @_;
    $self->{preprocess}  = $args->{preprocess};
    $self->{postprocess} = $args->{postprocess};
    $self;
}


# PSGI request handler
sub call($)
{   my ($self, $env) = @_;
    my $res = eval { $self->_call($env) };
    $res ||= Plack::Response->new
      ( RC_SERVER_ERROR
      , [Content_Type => 'text/plain']
      , [$@]
      );
    $res->finalize;
}

sub _call($;$)
{   my ($self, $env, $test_env) = @_;

    notice __x"WSA module loaded, but not used"
        if XML::Compile::SOAP::WSA->can('new') && !keys %{$self->{wsa_input}};
    $self->{wsa_input_rev}  = +{ reverse %{$self->{wsa_input}} };

    my $req = Plack::Request->new($test_env || $env);

    return $self->sendWsdl($req)
        if $req->method eq 'GET' && uc($req->uri->query || '') eq 'WSDL';

    if(my $pp = $self->{preprocess})
    {   $pp->($req);
    }

    my $method = $req->method;
    my $ct     = $req->content_type || 'text/plain';
    $ct =~ s/\;\s.*//;

    my ($rc, $msg, $err, $mime, $bytes);
    if($method ne 'POST' && $method ne 'M-POST')
    {   ($rc, $msg) = (RC_METHOD_NOT_ALLOWED, 'only POST or M-POST');
        $err = 'attempt to connect via GET';
    }
    elsif($ct !~ m/\bxml\b/)
    {   ($rc, $msg) = (RC_NOT_ACCEPTABLE, 'required is XML');
        $err = 'content-type seems to be text/plain, must be some XML';
    }
    else
    {   my $charset = $req->headers->content_type_charset || 'ascii';
        my $xmlin   = decode $charset, $req->content;
        my $action  = $req->header('SOAPAction') || '';
        $action     =~ s/["'\s]//g;   # sometimes illegal quoting and blanks "
        ($rc, $msg, my $xmlout) = $self->process(\$xmlin, $req, $action);

        if(UNIVERSAL::isa($xmlout, 'XML::LibXML::Document'))
        {   $bytes = $xmlout->toString($rc == RC_OK ? 0 : 1);
            $mime  = 'text/xml; charset="utf-8"';
        }
        else
        {   $err   = $xmlout;
        }
    }

    unless($bytes)
    {   $bytes = "[$rc] $err\n";
        $mime  = 'text/plain';
    }

    my $res = $req->new_response($rc,
      { Warning      => "199 $msg"
      , Content_Type => $mime
      }, $bytes);

    if(my $pp = $self->{postprocess})
    {   $pp->($req, $res);
    }

    $res->content_length(length $bytes);
    $res;
}

sub setWsdlResponse($;$)
{   my ($self, $fn, $ft) = @_;
    local *WSDL;
    open WSDL, '<:raw', $fn
        or fault __x"cannot read WSDL from {file}", file => $fn;
    local $/;
    $self->{wsdl_data} = <WSDL>;
    $self->{wsdl_type} = $ft || 'application/wsdl+xml';
    close WSDL;
}

sub sendWsdl($)
{   my ($self, $req) = @_;

    my $res = $req->new_response(RC_OK,
      { Warning        => '199 WSDL specification'
      , Content_Type   => $self->{wsdl_type}.'; charset=utf-8'
      , Content_Length => length($self->{wsdl_data})
      }, $self->{wsdl_data});

    $res;
}

#-----------------------------

1;


