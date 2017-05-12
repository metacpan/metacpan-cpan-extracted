#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
=head1 NAME

WebService::ProfitBricks::IpBlock - Manage IP blocks

=head1 DESCRIPTION

Manage the IP blocks.

=head1 SYNOPSIS

 my $block = IpBlock->new(blockSize => 2);
 $block->save;

=head1 METHODS

=over 4

=cut

package WebService::ProfitBricks::IpBlock;

use strict;
use warnings;
use Data::Dumper;

use WebService::ProfitBricks::Class;
use base qw(WebService::ProfitBricks);

attrs qw/blockId 
        region
        publicIps
        blockSize/;


=item list

=cut
does list => { through => "getAllPublicIpBlocks" };

=item find($ip)

Search the ip block to which $ip belongs to.

=cut
does find => { code => sub {
   my ($self, $search) = @_;
   my @blocks = $self->list;
   
   for my $block (@blocks) {
      for my $public_ip (@{ $block->publicIps }) {
         if($public_ip->{ip} eq $search) {
            return $block;
         }
      }
   }
}};

=item save

Reserves the amount of IPs given to the constructor.

=cut
sub save {
   my ($self) = @_;
   my $data = $self->connection->call("reservePublicIpBlock", blockSize => $self->blockSize, region => $self->region);
   push(@{ $data->{publicIps} }, map { {ip => $_} } @{ $data->{ips} });
   delete $data->{ips};
   $self->set_data($data);
}

=item reserve

Alias for I<save()>.

=cut
sub reserve {
   my ($self) = @_;
   $self->save;
}

=item release

Releases the current IP block.

=cut
sub release {
   my ($self) = @_;
   my $data = $self->connection->call("releasePublicIpBlock", blockId => $self->blockId);
}

=item removePublicIpFromNic($ip, $nicId)

Remove the given public ip ($ip) from the nic represented by $nicId.

=cut
sub removePublicIpFromNic {
   my ($self, $ip, $nicId) = @_;
   my $data = $self->connection->call("removePublicIpFromNic", ip => $ip, nicId => $nicId);
   print Dumper($data);
}

=back

=cut

1;
