#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

=head1 NAME

WebService::ProfitBricks::Storage - Manage servers.

=head1 DESCRIPTION

Manage the storages of your datacenter.

=head1 SYNOPSIS

 my $stor1 = $dc->storage->new(size => 50, storageName => "store01", mountImageId => $use_image, profitBricksImagePassword => $root_pw);
 $stor1->save;

=head1 METHODS

=over 4

=cut
   
package WebService::ProfitBricks::Storage;

use strict;
use warnings;

use WebService::ProfitBricks::Class;
use base qw(WebService::ProfitBricks);

attrs qw/storageId
        storageName
        creationTime
        lastModificationTime
        provisioningState
        size
        serverId
        mountImageId
        profitBricksImagePassword
        osType/;


serializer xml => { container => "arg0" };

belongs_to datacenter => "WebService::ProfitBricks::DataCenter" => { through => "dataCenterId" };

=item connect($server_id)

Connect the storage to a server.

 $stor1->connect($srv->serverId);

=cut
sub connect {
   my ($self, $server_id) = @_;
   my $data = $self->connection->call("connectStorageToServer", storageId => $self->storageId, serverId => $server_id);
   $self->provisioningState($data);
}

=back

=cut

"We've got brains!";
