#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

=head1 NAME

WebService::ProfitBricks::DataCenter - Manage DataCenter

=head1 DESCRIPTION

Manages the virtual datacenters.

=head1 SYNOPSIS

 use WebService::ProfitBricks qw/DataCenter/;
 WebService::ProfitBricks->auth($user, $password);
   
 my $dc = DataCenter->new(dataCenterName => "DC1", region => "EUROPE");
 $dc->save;
 $dc->wait_for_provisioning;
    
 my $dc = DataCenter->find("DC1");

=head1 METHODS

This class implements all methods from L<WebService::ProfitBricks> and these additional ones.

=over 4

=cut
   
package WebService::ProfitBricks::DataCenter;

use strict;
use warnings;

use Data::Dumper;
use WebService::ProfitBricks::Class;
use base qw(WebService::ProfitBricks);

attrs qw/dataCenterName
        dataCenterVersion
        dataCenterId 
        region 
        provisioningState/;

does find => { through => "dataCenterName" };
does list => { through => "getAllDataCenters" };

serializer "xml";

has_many server       => "WebService::ProfitBricks::Server"       => { through => "servers" };
has_many loadBalancer => "WebService::ProfitBricks::LoadBalancer" => { through => "loadBalancers" };
has_many storage      => "WebService::ProfitBricks::Storage"      => { through => "storages" };

=item wait_for_provisioning

Call this function if you modified something in your virtual datacenter (like adding a new server, new storage, ...). This will block until your modification is done.

=cut
sub wait_for_provisioning {
   my ($self) = @_;
   my $is_ready = 0;

   while($is_ready == 0) {
      $self->get_state;
      if(exists $self->{__data__}->{provisioningState} && $self->{__data__}->{provisioningState} eq "AVAILABLE") {
         $is_ready = 1;
         last;
      }

      sleep 3;
   }
}

=item get_state

This method returns the current provisioning state of your virtual datacenter.

=cut
sub get_state {
   my ($self) = @_;
   my $data = $self->connection->call("getDataCenterState", dataCenterId => $self->dataCenterId);
   $self->provisioningState($data);
}

=back

=cut

1;
