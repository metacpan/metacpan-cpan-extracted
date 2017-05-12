#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

=head1 NAME

WebService::ProfitBricks::Nic - Manage nics.

=head1 DESCRIPTION

Manage the nics of a server.

=head1 SYNOPSIS

 my $nic = $srv->eth->new(nicName => "intern", lanId => 2);
 $nic->save;
    
 my $nic2 = $srv->eth->new(nicName => "public", lanId => 3);
 $nic2->setInternetAccess(1);

=head1 METHODS

=over 4

=cut

package WebService::ProfitBricks::Nic;

use strict;
use warnings;

use WebService::ProfitBricks::Class;
use base qw(WebService::ProfitBricks);

attrs qw/nicId
        nicName
        serverId
        lanId
        internetAccess
        ip
        macAddress
       /;

serializer xml => { container => "arg0" };

belongs_to server => "WebService::ProfitBricks::Server" => { through => "serverId" };


=item setInternetAccess($has_access)

Set the internetAccess flags. 1 for true, 0 for false.

=cut
sub setInternetAccess {
   my ($self, $has_access) = @_;

   my $ret = $self->connection->call("setInternetAccess", nicId => $self->nicId, datacenterId => $self->server->dataCenterId, lanId => $self->lanId, internetAccess => ($has_access == 1 ? "true" : "false"));
   print Dumper($ret);
}

=back

=cut

"Can't connect to bot net!";
