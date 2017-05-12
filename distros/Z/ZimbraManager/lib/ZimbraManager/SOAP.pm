package ZimbraManager::SOAP;

use Mojo::Base -base;


use Mojo::Util qw(dumper);
use Mojo::Log;

use IO::Socket::SSL qw( SSL_VERIFY_NONE SSL_VERIFY_PEER );

use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::SOAP::Trace;
use XML::Compile::Transport::SOAPHTTP;

use HTTP::CookieJar::LWP;


has 'log' => sub {
    return Mojo::Log->new();
};


has 'soapDebug' => sub {
    my $self = shift;
    return 0;
};


has 'soapErrorsToConsumer' => sub {
    my $self = shift;
    return 0;
};


has 'mode' => sub {
    my $self = shift;
    return 'full';
};


has 'wsdlPath' => sub {
    my $self = shift;
    return "$FindBin::Bin/../etc/wsdl/";
};


has 'wsdlFile' => sub {
    my $self = shift;
    my $wsdlFile;
    my $mode = $self->mode;
    if   ($mode eq 'admin') {
        $wsdlFile = $self->wsdlPath.'ZimbraAdminService.wsdl';
    }
    elsif ($mode eq 'user') {
        $wsdlFile = $self->wsdlPath.'ZimbraUserService.wsdl';
    }
    elsif ($mode eq 'full') {
        $wsdlFile = $self->wsdlPath.'ZimbraService.wsdl';
    }
    else {
        die "no valid mode ($self->mode) for attribute wsdlFile has been set";
    }
    $self->log->debug("wsdlFile=$wsdlFile");
    return $wsdlFile;
};


has 'wsdlXml' => sub {
    my $self = shift;
    my $wsdlXml = XML::LibXML->new->parse_file($self->wsdlFile);
    return $wsdlXml;
};


has 'wsdl' => sub {
    my $self = shift;
    my $wsdlXml = $self->wsdlXml;
    my $wsdl = XML::Compile::WSDL11->new($wsdlXml);
    for my $xsd (glob $self->wsdlPath."*.xsd") {
        $self->log->debug("XML Schema Import of file:", $xsd);
        $wsdl->importDefinitions($xsd);
    }
    return $wsdl;
};


has 'zcsService' => sub {
    my $self = shift;
    my $mode = $self->mode;
    if    ($mode eq 'admin') {
        return 'zcsAdminService';
    }
    elsif ($mode eq 'user') {
        return 'zcsService';
    }
    elsif ($mode eq 'full') {
        return 'zcsAdminService';
    }
    else {
        die "no valid mode ($self->mode) for attribute zcsService has been set";
    }
};


has 'wsdlReturnParameterName' => sub {
    return 'params';
};


has 'service' => sub {
    my $self = shift;
    my $wsdlXml = $self->wsdlXml;
    my $zimbraServices;
    my $wsdlServices = $wsdlXml->getElementsByTagName( 'wsdl:service' );
    for my $service (@$wsdlServices) {
        my $name         = $service->getAttribute( 'name' );
        my $port         = $service->getElementsByTagName( 'wsdl:port' )->[0];
        my $port_name    = $port->getAttribute( 'name' );
        my $address      = $port->getElementsByTagName( 'soap:address' )->[0];
        my $uri          = $address->getAttribute( 'location' );
           $uri          =~ m/^(https|http):\/\/(.+?):(.+?)\//;
        my $uri_protocol = $1;
        my $uri_host     = $2;
        my $uri_port     = $3;

        $zimbraServices->{$name} = {
            host           => $uri_host,
            name           => $name,
            port_name      => $port_name,
            uri            => $uri,
            uri_host       => $uri_host,
            uri_port       => $uri_port,
            uri_protocol   => $uri_protocol,
        };
    }
    if ($self->log->level eq 'debug') {
        for my $servicename (keys %$zimbraServices) {
            for my $k (keys %{$zimbraServices->{$servicename}}) {
                $self->log->debug("$k=", $zimbraServices->{$servicename}->{$k});
            }
        }
    }
    return $zimbraServices->{$self->zcsService};
};


has 'transporter' => sub {
    my $self = shift;

    my $uri  = $self->service->{uri};

    my $verifyHostname = $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} // 1;
    my $verifyMode     = $ENV{PERL_LWP_SSL_VERIFY_MODE}     // SSL_VERIFY_PEER;

    # redirect the endpoint as specified in the WSDL to our own server.
    my $transporter = XML::Compile::Transport::SOAPHTTP->new(
        address    => $uri,
        keep_alive => 1,
        # for SSL handling we need our own LWP Agent
        user_agent => LWP::UserAgent->new(
            ssl_opts => { # default is SSL verification on
                # NOTE: PERL_LWP_SSL_VERIFY_MODE is not an "official" env variable
                verify_hostname => $verifyHostname,
                SSL_verify_mode => $verifyMode,
            },
        ),
    );

    $self->log->debug("LWP_SSL_VERIFY_HOSTNAME = $verifyHostname\n"
                    . "LWP_SSL_VERIFY_MODE     = $verifyMode");

    return $transporter;
};


has 'soapOps' => sub {
    my $self = shift;
    my $soapOps;

    my $port = $self->service->{port_name};
    my $name = $self->service->{name};
    my $send = $self->transporter->compileClient( port => $port );

    # Compile all service methods
    for my $soapOp ( $self->wsdl->operations( port => $port ) ) {
        $self->log->debug("Got soap operation " . $soapOp->name);
        $soapOps->{ $soapOp->name } =
        $self->wsdl->compileClient(
            $soapOp->name,
            port      => $port,
            service   => $name,
            transport => $send,
        );
    }
    return $soapOps;
};


sub callLegacy {
    my $self      = shift;
    my $action    = shift;
    my $args      = shift;
    my $authToken = shift;
    my $namedParameters = {
        action    => $action,
        args      => $args,
        authToken => $authToken,
    };
    return $self->call($namedParameters);
}

sub call {
    my $self            = shift;
    my $namedParameters = shift;
    if (ref $namedParmeters ne 'HASH') {
        $namedParameters = { @_ };
    }
    my $action          = $namedParameters->{action};
    my $args            = $namedParameters->{args};
    my $authToken       = $namedParameters->{authToken};

    my $uri = $self->service->{uri};

    # for each controller request build authentication token with cookieJar
    # HTTP::CookieJar::LWP is compatible with the original LWP cookie
    # mechanism but lightweight

    my $cookieJar = HTTP::CookieJar::LWP->new();
       $cookieJar->add( $uri, "ZM_ADMIN_AUTH_TOKEN=$authToken" ) if (defined $authToken);
    my $ua = $self->transporter->userAgent();
       $ua->cookie_jar($cookieJar);

    $self->log->debug(dumper({
        _function => 'ZimbraManager::Soap::call',
        action    =>$action,
        args      =>$args,
        authToken =>$authToken
    }));

    my ( $response, $trace ) = $self->soapOps->{$action}->($args);
    if ($self->soapDebug) {
        $self->log->debug(dumper ("call(): response=", $response));
        $self->log->debug(dumper ("call(): trace=",    $trace));
    }
    my $err;
    if ( not defined $response ) {
        $err = 'SOAP ERROR from Zimbra: undefined response';
        if ($self->soapErrorsToConsumer) {
            my $trace    = 'trace:    ' . dumper($trace);
            $err .= "\n\n\n$trace\n";
        }
    }
    elsif ( $response->{Fault} ) {
        $err = 'SOAP ERROR from Zimbra: '. $response->{Fault}->{faultstring};
        if ($self->soapErrorsToConsumer) {
            my $response = 'response: ' . dumper($response);
            my $trace    = 'trace:    ' . dumper($trace);
            $err .= "\n\n\n$response\n\n$trace\n";
        }
    }
    return ($response->{$self->wsdlReturnParameterName}, $err);
}

1;

=pod

=encoding UTF-8

=head1 NAME

ZimbraManager::SOAP

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    use ZimbraManager::SOAP;

    has 'soap' => sub {
        my $self = shift;
        return ZimbraManager::SOAP->new(
            log => $self->log,
            mode => 'full' # or 'admin' or 'user'
            # soapDebug => '1', # enables SOAP backend communication debugging
            # soapErrorsToConsumer => '1' # returns SOAP error to consumer

        );
    };

    my $namedParameters = {
        action    => 'FUNCTIONNAME',
        args      => \%DATASTRUCTUREDPARAMS,
        authToken => $authToken,
    };
    my ($ret, $err) = $self->soap->call($namedParameters);

also
    $self->soap->call(
        action    => 'FUNCTIONNAME',
        args      => \%DATASTRUCTUREDPARAMS,
        authToken => $authToken,
    );

is valid

=head1 DESCRIPTION

Helper class for Zimbra adminstration interface.

=head1 NAME

ZimbraManager::SOAP - class to manage Zimbra with perl and SOAP

=head1 ATTRIBUTES

=head2 Logging and Debugging Attributes

=head3 log

The mojo log object

=head3 soapDebug

Enabled SOAP debug output to $self->log

=head3 soapErrorsToConsumer

Returns soapErrors to the consumer in the return messages

=head2 mode

The zimbra SOAP interface has three modes:

    admin: adminstration access and commands in admin context
    user:  user accesses and commands in user context
    full:  both admin and user

=head2 wsdlPath

Path to WSDL and XML Schema file(s)

=head2 wsdlFile

Select WSDL file according to mode

=head2 wsdlXml

parsed WSDL as XML

=head2 wsdl

parsed WSDL as perl object with corresponding included XML Schema
and function stubs.

=head2 zcsService

Internal WSDL name for selecting mode

=head2 wsdlReturnParameterName

Name of the return value / structure

In Zimbra 8.0.7 this will be 'params' as defined here:

    <wsdl:definitions>
     ...
     <wsdl:message name="AdminAbortHsmRequestMessage">
      <wsdl:part name="params" element="zimbraAdmin:AbortHsmRequest"/>
     </wsdl:message>
     ...
    </wsdl:definitions>

In Zimbra 8.0.6 and previous versions this has been 'parameters' as defined here:

    <wsdl:definitions>
     ...
     <wsdl:message name="AdminAbortHsmRequestMessage">
      <wsdl:part name="parameters" element="zimbraAdmin:AbortHsmRequest"/>
     </wsdl:message>
     ...
    </wsdl:definitions>

=head2 service

Processed SOAP service URI on the server

=head2 transporter

Transporter for the SOAP calls - we are using LWP and handle these parameters

    - SSL VERIFY HOSTNAME (see IO::Socket::SSL)
    - SSL VERIFY MODE     (see IO::Socket::SSL)
    - HTTP keep_alive

=head2 soapOps

All usable SOAP operations exported by the the SOAP interface and with the selected
mode.

=head1 METHODS

All the methods of L<Mojo::Base> plus:

=head2 call

Calls Zimbra with the given argument and returns the SOAP response as perl hash.

=head1 COPYRIGHT

Copyright (c) 2014 by Roman Plessl. All rights reserved.

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see L<http://www.gnu.org/licenses/>.

=head1 AUTHOR

S<Roman Plessl E<lt>roman@plessl.infoE<gt>>

=head1 HISTORY

 2014-03-20 rp Initial Version
 2014-03-27 rp Improved Error and SSL Handling
 2014-04-29 rp Improved API and Session Handing

=head1 AUTHOR

Roman Plessl <rplessl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Roman Plessl.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__


# Emacs Configuration
#
# Local Variables:
# mode: cperl
# eval: (cperl-set-style "PerlStyle")
# mode: flyspell
# mode: flyspell-prog
# End:
#
# vi: sw=4 et
