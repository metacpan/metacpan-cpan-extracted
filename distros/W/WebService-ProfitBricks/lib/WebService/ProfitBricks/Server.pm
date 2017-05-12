#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

=head1 NAME

WebService::ProfitBricks::Server - Manage servers.

=head1 DESCRIPTION

Class to manage your servers.

=head1 SYNOPSIS

 my $srv = $dc->server->find_by_name("server01");
 my $srv = $dc->server->new(cores => 2, ram => 512, lanId => 1, internetAccess => 'true', bootFromStorageId => $store->storageId);

=cut
package WebService::ProfitBricks::Server;

use strict;
use warnings;

use WebService::ProfitBricks::Class;
use base qw(WebService::ProfitBricks);

attrs qw/serverId
        cores
        ram
        ips
        lanId
        osType
        internetAccess
        dataCenterId
        dataCenterVersion
        bootFromImageId
        bootFromStorageId
        nics
        provisioningState/;


attr serverName => { searchable => 1, find_by => "name", through => "datacenter" };

serializer xml => { container => "arg0" };

has_many eth => "WebService::ProfitBricks::Nic" => { through => "nics" };
belongs_to datacenter => "WebService::ProfitBricks::DataCenter" => { through => "dataCenterId" };


"Guns don't kill people.";
