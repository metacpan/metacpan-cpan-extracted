# Copyrights 2007-2017 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package XML::Compile::SOAP::Daemon::CGI;
use vars '$VERSION';
$VERSION = '3.13';

use parent 'XML::Compile::SOAP::Daemon';

use Log::Report 'xml-compile-soap-daemon';
use CGI 3.53, ':cgi';
use Encode;

# do not depend on LWP
use constant
  { RC_OK                 => 200
  , RC_METHOD_NOT_ALLOWED => 405
  , RC_NOT_ACCEPTABLE     => 406
  };


#--------------------

sub runCgiRequest(@) {shift->run(@_)}


# called by SUPER::run()
sub _run($;$)
{   my ($self, $args, $test_cgi) = @_;

    my $q      = $test_cgi || $args->{query} || CGI->new;
    my $method = $ENV{REQUEST_METHOD} || 'POST';
    my $qs     = $ENV{QUERY_STRING}   || '';
    my $ct     = $ENV{CONTENT_TYPE}   || 'text/plain';
    $ct =~ s/\;\s.*//;

    return $self->sendWsdl($q)
        if $method eq 'GET' && uc($qs) eq 'WSDL';

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
    {   my $charset = $q->charset || 'ascii';
        my $xmlin   = decode $charset, $q->param('POSTDATA');
        my $action  = $ENV{HTTP_SOAPACTION} || $ENV{SOAPACTION} || '';
        $action     =~ s/["'\s]//g;   # sometimes illegal quoting and blanks
        ($rc, $msg, my $xmlout) = $self->process(\$xmlin, $q, $action);

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

    my %headers =
      ( -status  => "$rc $msg"
      , -type    => $mime
      , -charset => 'utf-8'
      , -nph     => ($args->{nph} ? 1 : 0)
      );

    if(my $pp = $args->{postprocess})
    {   $pp->($args, \%headers, $rc, \$bytes);
    }

    $headers{-Content_length} = length $bytes;
    print $q->header(\%headers);
    print $bytes;
}

sub setWsdlResponse($;$)
{   my ($self, $fn, $ft) = @_;
    $fn or return;
    local *WSDL;
    open WSDL, '<:raw', $fn
        or fault __x"cannot read WSDL from {file}", file => $fn;
    local $/;
    $self->{wsdl_data} = <WSDL>;
    $self->{wsdl_type} = $ft || 'application/wsdl+xml';
    close WSDL;
}

sub sendWsdl($)
{   my ($self, $q) = @_;

    print $q->header
      ( -status  => RC_OK.' WSDL specification'
      , -type    => $self->{wsdl_type}
      , -charset => 'utf-8'
      , -nph     => 1

      , -Content_length => length($self->{wsdl_data})
      );

    print $self->{wsdl_data};
}
    
#-----------------------------


1;
