#!/usr/bin/env perl

require 5.010;
use strict;

use FindBin;
use lib "$FindBin::Bin/../thirdparty/lib/perl5";

use Data::Dumper;
$Data::Dumper::Indent = 1;

use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::Transport::SOAPHTTP;

my $VERSION = "0.15";

my $debug = 0;

my $service_port = 'zcsAdminServicePort';
my $service_name = 'zcsAdminService';

my $wsdlFile = "$FindBin::Bin/../etc/ZimbraService.wsdl";
if ($debug) { 
    warn "wsdlFile=$wsdlFile";
}

my $wsdlXml = XML::LibXML->new->parse_file($wsdlFile);

my $zimbraServices;
my $wsdlServices = $wsdlXml->getElementsByTagName( 'wsdl:service' );
for my $service (@$wsdlServices) {
    my $servicename = $service->getAttribute( 'name' );
    my $port        = $service->getElementsByTagName( 'wsdl:port' )->[0];
    my $address     = $port->getElementsByTagName( 'soap:address' )->[0];
    my $location    = $address->getAttribute( 'location' );
    $zimbraServices->{$servicename} = $location;
}

if ($debug) {
    for my $servicename (keys %$zimbraServices) {
        my $service_address = $zimbraServices->{$servicename};
           $service_address =~ m/^(https|http):\/\/(.+?):(.+?)\//;
        my $server_protocol = $1;
        my $server_host     = $2;
        my $server_port     = $3;

        warn "servicename=",     $servicename;
        warn "server_protocol=", $server_protocol;
        warn "server_host=",     $server_host;
        warn "server_port=",     $server_port;
        warn "service_address=", $service_address;
    }
}

my $wsdl = XML::Compile::WSDL11->new($wsdlXml);
for my $xsd (glob "$FindBin::Bin/../etc/*.xsd") {
    if ($debug) {
        warn "Import", $xsd;
    }
    $wsdl->importDefinitions($xsd);
}

# redirect the endpoint as specified in the WSDL to our own server.
my $transporter = XML::Compile::Transport::SOAPHTTP->new(
    address    => $zimbraServices->{$service_name},
    keep_alive => 1,
);

# enable cookies for zimbra Auth
my $ua = $transporter->userAgent();
$ua->cookie_jar({ file => "$ENV{HOME}/.cookies.txt" });

my $send = $transporter->compileClient( port => $service_port );

# Compile all service methods
my $soapOps = {};
for my $soapOp ( $wsdl->operations( port => $service_port ) ) {
    if ($debug) {
        my $msg = sprintf "got soap operation %s", $soapOp->name;
        warn $msg;
    }
    $soapOps->{ $soapOp->name } =
        $wsdl->compileClient(     $soapOp->name,
                                port      => $service_port,
                                transport => $send,
                                service   => $service_name );
}

auth();
print Dumper getAccountInfo('user@zimbra.example.com');
print Dumper getAllAccounts();


### call functions ###
# important ... SOAP functions are starting with a lower capital,
# instead of documented at
# http://wiki.zimbra.com/wiki/SOAP_API_Reference_Material_Beginning_with_ZCS_8.0
sub auth {
    call($soapOps,
         'authRequest',
         { persistAuthTokenCookie => 1,
           password => 'PASSWORD',
            account =>  {
                 by => 'name',
                  _ => 'admin'}} );
}

sub getAccountInfo {
    my $user = shift;
    my $ret;
    $ret = call($soapOps,
         'getAccountInfoRequest',
         { account => {
                    by => 'name',
                    _  => $user}});
    return $ret;
}

sub getAllAccounts {
    my $allAccounts =
    call($soapOps,
         'getAllAccountsRequest',
         { server => {
                   by => 'name',
                    _ => 'zimbra.example.com' },
           domain => {
                   by => 'name',
                    _ => 'zimbra.example.com' }});

    my $accounts;
    for my $za ( @{ $allAccounts->{account} } ) {
        my $name = $za->{name};
        my $id = $za->{id};
        my %kv = map { $_->{'n'} => $_->{'_'} } @{$za->{a}};
        $accounts->{$name} = {
            'name' => $name,
            'id' => $id,
            'kv' => \%kv,
        }
    }
    return $accounts;
}

### generic call function ###
sub call {
    my ($soapOps, $action, $args) = @_;
    my %argHash;
    @argHash{ keys %$args }  = values %$args;

    my ( $response, $trace ) = $soapOps->{$action}->(\%argHash);
    #warn Dumper ("call(): response=", $response);
    #warn Dumper ("call(): trace=", $trace);
    return $response->{parameters};
}

__END__

=head1 NAME

zimbra-admin-proof-of-concept.pl - access administative tools of zimbra with perl

=head1 SYNOPSIS

B<zimbra-admin-interface.pl> [I<options>...]

=head1 DESCRIPTION

zimbra-admin-interface is a proof of concept tools to test the Zimbra
SOAP interface in perl.

=head1 SEE ALSO

L<ZimbraManager::SOAP> L<ZimbraManager::SOAP::Friendly>

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

 2014-03-19 rp Initial Version

=cut
