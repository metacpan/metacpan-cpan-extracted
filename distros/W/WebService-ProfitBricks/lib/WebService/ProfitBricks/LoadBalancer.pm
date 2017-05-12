#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

=head1 NAME

WebService::ProfitBricks::LoadBalancer - Manage Loadbalancers

=head1 DESCRIPTION

Manage Loadbalancers.

=head1 METHODS

=over 4

=cut
   
package WebService::ProfitBricks::LoadBalancer;

use strict;
use warnings;
use Data::Dumper;

use WebService::ProfitBricks::Class;
use base qw(WebService::ProfitBricks);

attrs qw/loadBalancerId
        dataCenterId 
        loadBalancerAlgorithm
        ip
        lanId
        internetAccess
        serverIds/;

attr loadBalancerName => { searchable => 1, find_by => "name", through => "datacenter" };

serializer "xml";

belongs_to datacenter => "WebService::ProfitBricks::DataCenter" => { through => "dataCenterId" };

=item set_ip($ip)

Set ip for the loadbalancer.

 $lb->set_ip("1.2.3.4");

=cut
sub set_ip {
   my ($self, $ip) = @_;
   $self->ip($ip);
   my $data = $self->connection->call("updateLoadBalancer", xml => $self->to_xml(container => 1, ip => $ip, loadBalancerId => $self->loadBalancerId, loadBalancerName => $self->loadBalancerName, loadBalancerAlgorithm => $self->loadBalancerAlgorithm));
   print Dumper($data);
}

=item registerServersOnLoadBalancer(@server_ids)

Registerthe given servers to the loadbalancer.

 $lb->registerServersOnLoadBalancer($srv1->serverId, $srv2->serverId);

=cut
sub registerServersOnLoadBalancer {
   my ($self, @serverIds) = @_;
   my $data = $self->connection->call("registerServersOnLoadBalancer", xml => $self->to_xml(serverIds => \@serverIds, loadBalancerId => $self->loadBalancerId));
   $self->set_data($data);
}

=item deregisterServersOnLoadBalancer(@server_ids)

De-Register the given servers from the loadbalancer.

 $lb->deregisterServersOnLoadBalancer($srv1->serverId, $srv2->serverId);

=cut
sub deregisterServersOnLoadBalancer {
   my ($self, @serverIds) = @_;
   my $data = $self->connection->call("deregisterServersOnLoadBalancer", xml => $self->to_xml(serverIds => \@serverIds, loadBalancerId => $self->loadBalancerId));
   #$self->set_data($data);
}

=back

=cut

"This way! No that way";
